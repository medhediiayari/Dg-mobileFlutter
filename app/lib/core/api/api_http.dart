import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../auth/coffre.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import 'client_http.dart';
import 'dgflow_api.dart';

Json _j(dynamic d) => asJson(d);

/// Implémentation réelle : `AppConfig.apiUrl` + `/mobile/v1` (API hébergée par DG Flow web).
class ApiHttp implements DgFlowApi {
  ApiHttp(this.client);

  factory ApiHttp.depuisConfig({required Coffre coffre, required String versionApp}) => ApiHttp(
    ClientHttp(
      baseUrl: '${AppConfig.apiUrl}${AppConfig.prefixe}',
      coffre: coffre,
      versionApp: versionApp,
      plateforme: AppConfig.plateforme,
      delai: AppConfig.delai,
    ),
  );

  final ClientHttp client;

  Dio get _dio => client.dio;

  static final Options _publique = Options(extra: {ClientHttp.publique: true});

  @override
  set surSessionExpiree(void Function()? rappel) => client.surSessionExpiree = rappel;

  // ─── Session ────────────────────────────────────────────────────────────

  @override
  Future<Meta> meta() =>
      client.executer(() => _dio.get<dynamic>('/meta', options: _publique), (d) => Meta.fromJson(_j(d)));

  @override
  Future<bool> restaurerSession() => client.chargerJetons();

  Future<ReponseConnexion> _ouvrir(ReponseConnexion r) async {
    await client.enregistrerJetons(Jetons(accessToken: r.accessToken, refreshToken: r.refreshToken));
    return r;
  }

  @override
  Future<ReponseConnexion> connexion({
    required String email,
    required String motDePasse,
    String? appareil,
    String? plateforme,
  }) async {
    final r = await client.executer(
      () => _dio.post<dynamic>(
        '/auth/login',
        data: {'email': email.trim(), 'motDePasse': motDePasse, 'appareil': ?appareil, 'plateforme': ?plateforme},
        options: _publique,
      ),
      (d) => ReponseConnexion.fromJson(_j(d)),
    );
    return _ouvrir(r);
  }

  @override
  Future<ReponseConnexion> connexionMicrosoft({
    required String accessToken,
    String? appareil,
    String? plateforme,
  }) async {
    final r = await client.executer(
      () => _dio.post<dynamic>(
        '/auth/microsoft',
        data: {'accessToken': accessToken, 'appareil': ?appareil, 'plateforme': ?plateforme},
        options: _publique,
      ),
      (d) => ReponseConnexion.fromJson(_j(d)),
    );
    return _ouvrir(r);
  }

  @override
  Future<void> deconnexion() async {
    try {
      if (client.jetons != null) {
        await client.executer(() => _dio.post<dynamic>('/auth/logout'), (_) {});
      }
    } catch (_) {
      // Serveur injoignable : la session expirera d'elle-même ; on déconnecte localement.
    } finally {
      await client.enregistrerJetons(null);
    }
  }

  @override
  Future<Profil> moi() => client.executer(() => _dio.get<dynamic>('/me'), (d) => Profil.fromJson(_j(d)));

  @override
  Future<Profil> changerRole(int roleId) => client.executer(
    () => _dio.post<dynamic>('/me/role-actif', data: {'roleId': roleId}),
    (d) => Profil.fromJson(_j(d)),
  );

  @override
  Future<List<SessionAppareil>> sessions() =>
      client.executer(() => _dio.get<dynamic>('/me/sessions'), (d) => asList(d, SessionAppareil.fromJson));

  @override
  Future<void> revoquerSession(String sid) => client.executer(() => _dio.delete<dynamic>('/me/sessions/$sid'), (_) {});

  @override
  Future<void> enregistrerAppareil({
    required String installationId,
    required String jeton,
    required String plateforme,
  }) => client.executer(
    () => _dio.post<dynamic>(
      '/me/appareils',
      data: {'installationId': installationId, 'jeton': jeton, 'plateforme': plateforme},
    ),
    (_) {},
  );

  @override
  Future<void> supprimerAppareil(String installationId) =>
      client.executer(() => _dio.delete<dynamic>('/me/appareils/$installationId'), (_) {});

  // ─── RC ─────────────────────────────────────────────────────────────────

  @override
  Future<ReponseListe> liste(FiltresListe filtres, {int page = 1, int limite = 25}) => client.executer(
    () => _dio.get<dynamic>(
      '/rc',
      queryParameters: filtres.parametres(page: page, limite: limite),
    ),
    (d) => ReponseListe.fromJson(_j(d)),
  );

  @override
  Future<Detail> detail(int rcId) =>
      client.executer(() => _dio.get<dynamic>('/rc/$rcId'), (d) => Detail.fromJson(_j(d)));

  @override
  Future<Parcours> parcours(int rcId) =>
      client.executer(() => _dio.get<dynamic>('/rc/$rcId/parcours'), (d) => Parcours.fromJson(_j(d)));

  @override
  Future<Tableau> tableau(int rcId) =>
      client.executer(() => _dio.get<dynamic>('/rc/$rcId/tableau'), (d) => Tableau.fromJson(_j(d)));

  @override
  Future<Consultation> enregistrerConsultation(int rcId, TypeConsultation type) => client.executer(
    () => _dio.post<dynamic>('/rc/$rcId/consultations', data: {'type': type.code}),
    (d) => Consultation.fromJson(_j(d)),
  );

  Future<ResultatDecision> _decision(int rcId, String action, Map<String, dynamic> corps) => client.executer(
    () => _dio.post<dynamic>('/rc/$rcId/$action', data: corps),
    (d) => ResultatDecision.fromJson(_j(d)),
  );

  @override
  Future<ResultatDecision> approuver(int rcId, {String? commentaire}) => _decision(rcId, 'approuver', {
    if (commentaire != null && commentaire.trim().isNotEmpty) 'commentaire': commentaire.trim(),
  });

  @override
  Future<ResultatDecision> rejeter(int rcId, {required String motif, int? destinataireId}) =>
      _decision(rcId, 'rejeter', {'motif': motif.trim(), 'destinataireId': ?destinataireId});

  @override
  Future<ResultatDecision> demanderInfo(int rcId, {required int destinataireId, required String message}) =>
      _decision(rcId, 'demande-info', {'destinataireId': destinataireId, 'message': message.trim()});

  @override
  Future<ResultatDecision> repondreInfo(int rcId, {required String message}) =>
      _decision(rcId, 'reponse-info', {'message': message.trim()});

  @override
  Future<ResultatDecision> bonDeCommande(int rcId, {required bool actif}) =>
      _decision(rcId, 'bon-de-commande', {'actif': actif});

  @override
  Future<ResultatPieces> envoyerPieces(
    int rcId,
    int evenementId,
    List<PieceLocale> pieces, {
    Progression? progression,
  }) async {
    final formulaire = FormData();
    for (final p in pieces) {
      formulaire.files.add(
        MapEntry(
          'files',
          await MultipartFile.fromFile(p.chemin, filename: p.nom, contentType: DioMediaType.parse(p.type)),
        ),
      );
    }
    return client.executer(
      () => _dio.post<dynamic>(
        '/rc/$rcId/evenements/$evenementId/pieces',
        data: formulaire,
        onSendProgress: progression,
        options: Options(sendTimeout: AppConfig.delaiEnvoi, receiveTimeout: AppConfig.delaiEnvoi),
      ),
      (d) => ResultatPieces.fromJson(_j(d)),
    );
  }

  @override
  Future<List<FichierDossier>> fichiers(int rcId) => client.executer(
    () => _dio.get<dynamic>('/rc/$rcId/fichiers'),
    (d) => asList(_j(d)['elements'], FichierDossier.fromJson),
  );

  @override
  Future<File> telecharger(String chemin, String nom, {Progression? progression}) async {
    // Un appel authentifié léger rafraîchit le jeton s'il a expiré (le flux
    // binaire d'un téléchargement ne porte pas de code d'erreur lisible).
    await nonLues();
    final dossier = await getTemporaryDirectory();
    final local = await fichierTelechargement(dossier, nom);
    await client.executer(
      () => _dio.download(
        chemin,
        local.path,
        onReceiveProgress: progression,
        options: Options(receiveTimeout: AppConfig.delaiEnvoi),
      ),
      (_) {},
    );
    return local;
  }

  // ─── Notifications ──────────────────────────────────────────────────────

  @override
  Future<PageNotifications> notifications({int? avant, int limite = 30, bool nonLuesSeulement = false}) =>
      client.executer(
        () => _dio.get<dynamic>(
          '/notifications',
          queryParameters: {'limite': '$limite', 'avant': ?avant?.toString(), if (nonLuesSeulement) 'nonLues': '1'},
        ),
        (d) => PageNotifications.fromJson(_j(d)),
      );

  @override
  Future<int> nonLues() =>
      client.executer(() => _dio.get<dynamic>('/notifications/non-lues'), (d) => asInt(_j(d)['total']));

  @override
  Future<void> marquerLue(int id) => client.executer(() => _dio.post<dynamic>('/notifications/$id/lue'), (_) {});

  @override
  Future<int> toutLire() =>
      client.executer(() => _dio.post<dynamic>('/notifications/tout-lire'), (d) => asInt(_j(d)['marquees']));
}

/// Fichier local d'un téléchargement : un sous-dossier par téléchargement, pour
/// garder le nom d'origine (c'est lui que voient Excel et la feuille de partage).
Future<File> fichierTelechargement(Directory racine, String nom) async {
  final dossier = Directory('${racine.path}/telechargements/${DateTime.now().microsecondsSinceEpoch}');
  await dossier.create(recursive: true);
  return File('${dossier.path}/${nomFichierSur(nom)}');
}

/// Nom de fichier local sans caractères problématiques (accents conservés).
String nomFichierSur(String nom) {
  final s = nom.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]+'), '_').trim();
  return s.isEmpty ? 'fichier' : s;
}
