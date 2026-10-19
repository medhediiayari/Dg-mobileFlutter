import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

import '../config/app_config.dart';
import '../models/profil.dart';

/// Connexion « DG Group » (Microsoft Entra ID), PKCE, client public.
///
/// L'app obtient un jeton Graph (`User.Read`) auprès de l'autorité
/// `https://login.microsoftonline.com/<tenantId>/v2.0` et le transmet à l'API
/// (`POST /auth/microsoft`), qui vérifie tenant / application puis lit l'email
/// via Graph — même règle que le web : l'email doit exister et être actif.
///
/// Redirection à déclarer dans Entra ID (« Applications mobiles et de bureau ») :
/// `dgflowrcflutter://auth`.
class ConnexionMicrosoft {
  const ConnexionMicrosoft([this._appAuth = const FlutterAppAuth()]);

  final FlutterAppAuth _appAuth;

  /// Jeton d'accès Graph, ou null si l'utilisateur a annulé.
  Future<String?> jetonGraph(SsoMicrosoft config) async {
    final autorite = 'https://login.microsoftonline.com/${config.tenantId}';
    try {
      final r = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          config.clientId,
          AppConfig.redirectionMicrosoft,
          scopes: const ['openid', 'profile', 'User.Read'],
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: '$autorite/oauth2/v2.0/authorize',
            tokenEndpoint: '$autorite/oauth2/v2.0/token',
          ),
          promptValues: const ['select_account'],
        ),
      );
      return r.accessToken;
    } on FlutterAppAuthUserCancelledException {
      return null;
    } on PlatformException catch (e) {
      throw ErreurMicrosoft(e.message ?? 'Connexion Microsoft impossible');
    }
  }
}

class ErreurMicrosoft implements Exception {
  const ErreurMicrosoft(this.message);

  final String message;

  @override
  String toString() => message;
}
