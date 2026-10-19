import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dgflow_rc/core/api/api_exception.dart';
import 'package:dgflow_rc/core/api/api_http.dart';
import 'package:dgflow_rc/core/api/client_http.dart';
import 'package:dgflow_rc/core/api/dgflow_api.dart';
import 'package:dgflow_rc/core/auth/coffre.dart';
import 'package:dgflow_rc/core/models/models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serveur simulé au niveau de l'adaptateur HTTP de dio.
class ServeurFaux implements HttpClientAdapter {
  ServeurFaux(this.repondre);

  final FutureOr<(int, Object?)> Function(RequestOptions o) repondre;
  final List<RequestOptions> requetes = [];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? corps, Future<void>? annulation) async {
    requetes.add(o);
    final (statut, json) = await repondre(o);
    if (statut == -1) {
      throw DioException.connectionError(requestOptions: o, reason: 'hors ligne');
    }
    return ResponseBody.fromString(
      json == null ? '' : jsonEncode(json),
      statut,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}

  int compter(String chemin) => requetes.where((r) => r.path == chemin).length;
}

Map<String, dynamic> erreur(String code, [String message = 'Erreur']) => {'error': message, 'code': code};

const _rafraichi = {
  'accessToken': 'acces-2',
  'refreshToken': 'sid.secret-2-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  'expiresIn': 900,
};

Future<(ApiHttp, ServeurFaux, CoffreMemoire)> creer(
  FutureOr<(int, Object?)> Function(RequestOptions o) repondre,
) async {
  final serveur = ServeurFaux(repondre);
  final coffre = CoffreMemoire({
    Cles.jetons: const Jetons(
      accessToken: 'acces-1',
      refreshToken: 'sid.secret-1-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    ).encoder(),
  });
  final client = ClientHttp(
    baseUrl: 'http://api.test/mobile/v1',
    coffre: coffre,
    versionApp: '1.0.0',
    plateforme: 'android',
    adaptateur: serveur,
  );
  final api = ApiHttp(client);
  await api.restaurerSession();
  return (api, serveur, coffre);
}

String? jeton(RequestOptions o) => o.headers['Authorization'] as String?;

void main() {
  test('en-têtes : Bearer, version et plateforme ; route publique sans jeton', () async {
    final (api, serveur, _) = await creer((o) {
      if (o.path == '/meta') {
        return (
          200,
          {
            'api': '1',
            'versionMinimaleApp': '1.0.0',
            'sso': {'microsoft': null},
          },
        );
      }
      return (200, {'total': 3});
    });
    expect(await api.nonLues(), 3);
    await api.meta();
    final prive = serveur.requetes.first;
    expect(prive.uri.toString(), 'http://api.test/mobile/v1/notifications/non-lues');
    expect(jeton(prive), 'Bearer acces-1');
    expect(prive.headers['X-App-Version'], '1.0.0');
    expect(prive.headers['X-App-Platform'], 'android');
    expect(jeton(serveur.requetes.last), isNull);
  });

  test(
    '401 TOKEN_INVALID : un seul rafraîchissement pour des requêtes concurrentes, puis nouvelle tentative',
    () async {
      final (api, serveur, coffre) = await creer((o) async {
        if (o.path == '/auth/refresh') {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          expect((o.data as Map)['refreshToken'], 'sid.secret-1-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
          return (200, _rafraichi);
        }
        return jeton(o) == 'Bearer acces-2' ? (200, {'total': 5}) : (401, erreur('TOKEN_INVALID'));
      });
      final resultats = await Future.wait([api.nonLues(), api.nonLues(), api.nonLues()]);
      expect(resultats, [5, 5, 5]);
      expect(serveur.compter('/auth/refresh'), 1);
      expect(jeton(serveur.requetes.firstWhere((r) => r.path == '/auth/refresh')), isNull);
      final stockes = Jetons.decoder(await coffre.lire(Cles.jetons));
      expect(stockes?.accessToken, 'acces-2');
      expect(stockes?.refreshToken, startsWith('sid.secret-2'));
    },
  );

  test('rafraîchissement refusé : jetons effacés, retour à la connexion', () async {
    var expiree = 0;
    final (api, serveur, coffre) = await creer((o) {
      if (o.path == '/auth/refresh') return (401, erreur('REFRESH_INVALID', 'Session expirée, reconnectez-vous'));
      return (401, erreur('TOKEN_INVALID', 'Session expirée, reconnectez-vous'));
    });
    api.surSessionExpiree = () => expiree++;
    await expectLater(api.detail(142), throwsA(isA<ApiException>().having((e) => e.statut, 'statut', 401)));
    expect(expiree, 1);
    expect(await coffre.lire(Cles.jetons), isNull);
    expect(serveur.compter('/auth/refresh'), 1);
  });

  test('session révoquée : pas de rafraîchissement, déconnexion immédiate', () async {
    var expiree = 0;
    final (api, serveur, coffre) = await creer(
      (o) => (401, erreur('SESSION_REVOKED', 'Session révoquée, reconnectez-vous')),
    );
    api.surSessionExpiree = () => expiree++;
    await expectLater(api.moi(), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'SESSION_REVOKED')));
    expect(serveur.compter('/auth/refresh'), 0);
    expect(expiree, 1);
    expect(await coffre.lire(Cles.jetons), isNull);
  });

  test('409 REFRESH_CONCURRENT : reprend les jetons déjà renouvelés par un autre appel', () async {
    late CoffreMemoire coffreRef;
    final (api, serveur, coffre) = await creer((o) async {
      if (o.path == '/auth/refresh') {
        // Un autre isolat a fait tourner le jeton entre-temps.
        await coffreRef.ecrire(
          Cles.jetons,
          const Jetons(accessToken: 'acces-3', refreshToken: 'sid.secret-3').encoder(),
        );
        return (409, erreur('REFRESH_CONCURRENT', 'Renouvellement déjà en cours'));
      }
      return jeton(o) == 'Bearer acces-3' ? (200, {'total': 1}) : (401, erreur('TOKEN_INVALID'));
    });
    coffreRef = coffre;
    expect(await api.nonLues(), 1);
    expect(serveur.compter('/auth/refresh'), 1);
  });

  test('réseau absent : erreur NETWORK, session conservée', () async {
    final (api, _, coffre) = await creer((o) => (-1, null));
    await expectLater(
      api.liste(FiltresListe.aTraiter),
      throwsA(isA<ApiException>().having((e) => e.reseau, 'reseau', isTrue).having((e) => e.statut, 'statut', 0)),
    );
    expect(await coffre.lire(Cles.jetons), isNotNull);
  });

  test('erreurs métier : code et message de l’API', () async {
    final (api, _, _) = await creer((o) {
      if (o.path == '/rc/142/approuver') {
        return (409, erreur('CONSULTATION_TABLEAU_REQUISE', "Consultez le tableau comparatif avant d'approuver."));
      }
      if (o.path == '/rc/143/approuver') {
        return (400, {...erreur('PAIEMENT_INCOHERENT', 'Paiement incohérent'), 'message': 'détail'});
      }
      return (404, null);
    });
    await expectLater(
      api.approuver(142),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statut, 'statut', 409)
            .having((e) => e.gardeConsultation, 'garde', isTrue)
            .having((e) => e.message, 'message', contains('tableau comparatif')),
      ),
    );
    await expectLater(
      api.approuver(143),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'PAIEMENT_INCOHERENT')
            .having((e) => e.details?['message'], 'détails', 'détail'),
      ),
    );
    await expectLater(api.parcours(1), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'HTTP_ERROR')));
  });

  test('corps des décisions et de la connexion', () async {
    final (api, serveur, coffre) = await creer((o) {
      if (o.path == '/auth/login') {
        return (
          200,
          {
            'accessToken': 'a',
            'refreshToken': 'r' * 60,
            'expiresIn': 900,
            'utilisateur': {
              'id': 1,
              'nom': 'N',
              'prenom': 'P',
              'email': 'e',
              'roleActif': {'id': 3, 'nom': 'x', 'libelle': 'x'},
              'roles': [],
              'lectureSeule': false,
            },
          },
        );
      }
      return (200, {'succes': true, 'message': 'ok', 'statut': 's', 'evenementId': 12});
    });
    await api.connexion(email: '  camille@dggroup.fr ', motDePasse: 'secret', appareil: 'Pixel', plateforme: 'android');
    expect(serveur.requetes.last.data, {
      'email': 'camille@dggroup.fr',
      'motDePasse': 'secret',
      'appareil': 'Pixel',
      'plateforme': 'android',
    });
    expect(jeton(serveur.requetes.last), isNull);
    expect(Jetons.decoder(await coffre.lire(Cles.jetons))?.accessToken, 'a');

    await api.approuver(5, commentaire: '  ');
    expect(serveur.requetes.last.data, <String, dynamic>{});
    await api.rejeter(5, motif: ' Motif ', destinataireId: 21);
    expect(serveur.requetes.last.data, {'motif': 'Motif', 'destinataireId': 21});
    await api.rejeter(5, motif: 'Motif');
    expect(serveur.requetes.last.data, {'motif': 'Motif'});
    await api.demanderInfo(5, destinataireId: 26, message: 'Question ?');
    expect(serveur.requetes.last.path, '/rc/5/demande-info');
    await api.repondreInfo(5, message: 'Réponse');
    expect(serveur.requetes.last.path, '/rc/5/reponse-info');
    final r = await api.bonDeCommande(5, actif: true);
    expect(serveur.requetes.last.data, {'actif': true});
    expect(r.evenementId, 12);
    await api
        .enregistrerConsultation(5, TypeConsultation.tableau)
        .catchError(
          (_) => const Consultation(
            autorise: false,
            documentOk: false,
            tableauOk: false,
            tableauRequis: true,
            perimee: false,
          ),
        );
    expect(serveur.requetes.last.data, {'type': 'TABLEAU'});
  });

  test('déconnexion : révoque la session puis efface les jetons, même hors ligne', () async {
    final (api, serveur, coffre) = await creer((o) => (-1, null));
    await api.deconnexion();
    expect(serveur.requetes.single.path, '/auth/logout');
    expect(await coffre.lire(Cles.jetons), isNull);
  });

  test('téléchargement : un 401 sur un flux binaire déclenche aussi le renouvellement', () async {
    final (api, serveur, _) = await creer((o) {
      if (o.path == '/auth/refresh') return (200, _rafraichi);
      return jeton(o) == 'Bearer acces-2' ? (200, {'ok': true}) : (401, erreur('TOKEN_INVALID'));
    });
    final r = await api.client.executer(
      () => api.client.dio.get<dynamic>('/rc/1/pieces/2', options: Options(responseType: ResponseType.stream)),
      (d) => d,
    );
    expect(r, isA<ResponseBody>());
    expect(serveur.compter('/auth/refresh'), 1);
  });

  test('renouvellement impossible faute de réseau : erreur NETWORK, session conservée', () async {
    var expiree = 0;
    final (api, _, coffre) = await creer((o) {
      if (o.path == '/auth/refresh') return (-1, null);
      return (401, erreur('TOKEN_INVALID'));
    });
    api.surSessionExpiree = () => expiree++;
    await expectLater(api.nonLues(), throwsA(isA<ApiException>().having((e) => e.reseau, 'réseau', isTrue)));
    expect(expiree, 0);
    expect(await coffre.lire(Cles.jetons), isNotNull);
  });

  test('un 401 tardif d’une session précédente n’efface pas la nouvelle', () async {
    final attente = Completer<void>();
    final recue = Completer<void>();
    final (api, _, coffre) = await creer((o) async {
      recue.complete();
      await attente.future;
      return (401, erreur('SESSION_REVOKED'));
    });
    var expiree = 0;
    api.surSessionExpiree = () => expiree++;
    final ancienne = api.nonLues();
    await recue.future;
    await api.client.enregistrerJetons(const Jetons(accessToken: 'nouvelle', refreshToken: 'nouvelle-r'));
    attente.complete();
    await expectLater(ancienne, throwsA(isA<ApiException>()));
    expect(expiree, 0);
    expect(Jetons.decoder(await coffre.lire(Cles.jetons))?.accessToken, 'nouvelle');
  });
}
