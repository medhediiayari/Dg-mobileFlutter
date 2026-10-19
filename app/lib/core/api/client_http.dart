import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../auth/coffre.dart';
import '../models/profil.dart';
import 'api_exception.dart';

/// Issue d'un renouvellement des jetons.
enum Renouvellement {
  /// Nouveaux jetons enregistrés.
  fait,

  /// Refusé (jeton invalide, session révoquée, accès changé) : retour à la connexion.
  refuse,

  /// Serveur injoignable : la session est conservée, la requête échoue en « réseau ».
  reseau,
}

/// Client HTTP de l'API mobile DG Flow.
///
/// - Jeton d'accès court + jeton de rafraîchissement à rotation.
/// - Sur 401 `TOKEN_INVALID` : UN seul rafraîchissement à la fois (les requêtes
///   concurrentes l'attendent), puis une seule nouvelle tentative. Deux
///   rafraîchissements simultanés avec le même jeton feraient répondre
///   `409 REFRESH_CONCURRENT` (puis révoquer la session : détection de rejeu).
/// - Rafraîchissement refusé, session révoquée, compte désactivé, accès changé :
///   jetons effacés et [surSessionExpiree] appelé (retour à la connexion).
class ClientHttp {
  ClientHttp({
    required String baseUrl,
    required this.coffre,
    required String versionApp,
    required String plateforme,
    Duration delai = const Duration(seconds: 15),
    HttpClientAdapter? adaptateur,
  }) : dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: delai,
           receiveTimeout: delai,
           sendTimeout: delai,
           headers: {'Accept': 'application/json', 'X-App-Version': versionApp, 'X-App-Platform': plateforme},
         ),
       ) {
    if (adaptateur != null) dio.httpClientAdapter = adaptateur;
    dio.interceptors.add(InterceptorsWrapper(onRequest: _avantRequete, onError: _surErreur));
  }

  final Dio dio;
  final Coffre coffre;
  Jetons? _jetons;
  Future<Renouvellement>? _rafraichissement;

  void Function()? surSessionExpiree;

  /// Option `extra` : la route est publique (pas d'en-tête Authorization).
  static const String publique = 'publique';
  static const String _dejaRejoue = 'rejoue';

  Jetons? get jetons => _jetons;
  String? get jetonAcces => _jetons?.accessToken;

  Future<bool> chargerJetons() async {
    _jetons = Jetons.decoder(await coffre.lire(Cles.jetons));
    return _jetons != null;
  }

  Future<void> enregistrerJetons(Jetons? j) async {
    _jetons = j;
    if (j == null) {
      await coffre.effacer(Cles.jetons);
    } else {
      await coffre.ecrire(Cles.jetons, j.encoder());
    }
  }

  void _avantRequete(RequestOptions o, RequestInterceptorHandler h) {
    if (o.extra[publique] != true && _jetons != null) {
      o.headers['Authorization'] = 'Bearer ${_jetons!.accessToken}';
    }
    h.next(o);
  }

  Future<void> _surErreur(DioException e, ErrorInterceptorHandler h) async {
    final o = e.requestOptions;
    final r = e.response;
    if (r?.statusCode == 401 && o.extra[publique] != true && o.extra[_dejaRejoue] != true && _jetons != null) {
      // Un téléchargement reçoit un flux binaire, pas le JSON de l'erreur : on
      // tente alors le renouvellement (une session révoquée le refusera).
      final flux = o.responseType == ResponseType.stream || r!.data is ResponseBody;
      if (flux || codeDe(r.data) == 'TOKEN_INVALID') {
        // Un autre appel a peut-être déjà renouvelé les jetons pendant celui-ci.
        final envoye = o.headers['Authorization'];
        final issue = envoye != 'Bearer ${_jetons!.accessToken}' ? Renouvellement.fait : await rafraichir();
        if (issue == Renouvellement.reseau) {
          // Serveur injoignable pendant le renouvellement : erreur réseau, session conservée.
          return h.next(DioException.connectionError(requestOptions: o, reason: 'renouvellement impossible'));
        }
        final courant = _jetons;
        if (issue == Renouvellement.fait && courant != null) {
          o.extra[_dejaRejoue] = true;
          o.headers['Authorization'] = 'Bearer ${courant.accessToken}';
          if (o.data is FormData) o.data = (o.data as FormData).clone();
          try {
            return h.resolve(await dio.fetch<dynamic>(o));
          } on DioException catch (e2) {
            return h.next(e2);
          }
        }
      }
    }
    h.next(e);
  }

  /// Rafraîchit les jetons, une seule fois à la fois.
  Future<Renouvellement> rafraichir() {
    if (_jetons == null) return Future.value(Renouvellement.refuse);
    return _rafraichissement ??= _rafraichirMaintenant().whenComplete(() => _rafraichissement = null);
  }

  Future<Renouvellement> _rafraichirMaintenant() async {
    final envoye = _jetons!.refreshToken;
    try {
      final r = await dio.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': envoye},
        options: Options(extra: {publique: true}),
      );
      final j = JetonsRafraichis.fromJson((r.data as Map).cast<String, dynamic>());
      if (j.accessToken.isEmpty || j.refreshToken.isEmpty) return Renouvellement.refuse;
      await enregistrerJetons(Jetons(accessToken: j.accessToken, refreshToken: j.refreshToken));
      return Renouvellement.fait;
    } on DioException catch (e) {
      final r = e.response;
      // Réseau absent : on garde la session, la requête échouera en « réseau ».
      if (r == null) return Renouvellement.reseau;
      if (r.statusCode == 409 && codeDe(r.data) == 'REFRESH_CONCURRENT') {
        // Un autre renouvellement (autre isolat, notification…) a déjà fait tourner
        // le jeton : on reprend celui qui a été enregistré, s'il est plus récent.
        final stockes = Jetons.decoder(await coffre.lire(Cles.jetons));
        if (stockes != null && stockes.refreshToken != envoye) {
          _jetons = stockes;
          return Renouvellement.fait;
        }
      }
      return Renouvellement.refuse;
    } catch (_) {
      return Renouvellement.refuse;
    }
  }

  /// Exécute une requête et convertit toute erreur en [ApiException].
  Future<T> executer<T>(Future<Response<dynamic>> Function() requete, T Function(dynamic donnees) lire) async {
    try {
      final r = await requete();
      return lire(r.data);
    } on DioException catch (e) {
      final erreur = versApiException(e);
      final publiqueRoute = e.requestOptions.extra[publique] == true;
      // Une réponse tardive à une requête d'une session précédente ne doit pas
      // effacer les jetons d'une nouvelle connexion.
      final envoye = e.requestOptions.headers['Authorization'];
      final sessionCourante = _jetons == null || envoye == null || envoye == 'Bearer ${_jetons!.accessToken}';
      if (erreur.statut == 401 && !publiqueRoute && sessionCourante) {
        await enregistrerJetons(null);
        surSessionExpiree?.call();
      }
      throw erreur;
    }
  }

  static String? codeDe(Object? donnees) {
    final j = _json(donnees);
    final code = j?['code'];
    return code is String ? code : null;
  }

  static Map<String, dynamic>? _json(Object? donnees) {
    if (donnees is Map) return donnees.cast<String, dynamic>();
    if (donnees is String && donnees.isNotEmpty) {
      try {
        final d = jsonDecode(donnees);
        return d is Map ? d.cast<String, dynamic>() : null;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static ApiException versApiException(DioException e) {
    final r = e.response;
    if (r == null) {
      final delai =
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;
      return ApiException(
        0,
        delai
            ? 'Le serveur ne répond pas. Vérifiez votre connexion (et le VPN si l’API est interne).'
            : 'Serveur injoignable. Vérifiez votre connexion (et le VPN si l’API est interne).',
        ApiException.codeReseau,
      );
    }
    final j = _json(r.data);
    final statut = r.statusCode ?? 0;
    return ApiException(
      statut,
      (j?['error'] is String ? j!['error'] as String : null) ?? 'Erreur $statut',
      (j?['code'] is String ? j!['code'] as String : null) ?? 'HTTP_ERROR',
      j,
    );
  }
}
