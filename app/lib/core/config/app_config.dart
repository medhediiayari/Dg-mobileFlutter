import 'package:flutter/foundation.dart';

/// Configuration de compilation (`--dart-define`).
///
/// - `API_URL` : URL de DG Flow web, qui héberge l'API mobile (sans le préfixe
///   `/mobile/v1`). Par défaut `http://10.0.2.2:3000` sur Android (émulateur →
///   PC hôte), `http://localhost:3000` ailleurs.
/// - `DEMO=true` : mode démonstration, API simulée en mémoire.
abstract final class AppConfig {
  static const String _apiUrlDefini = String.fromEnvironment('API_URL');

  /// Mode démonstration (API en mémoire, aucune requête réseau).
  static const bool demo = bool.fromEnvironment('DEMO');

  /// Préfixe des routes de l'API mobile (même contrat que l'API de l'app React Native).
  static const String prefixe = '/mobile/v1';

  /// Délai maximal d'une requête : sans lui, une API arrêtée bloquerait le démarrage.
  static const Duration delai = Duration(seconds: 15);

  /// Délai des envois de pièces jointes (photos, PDF jusqu'à 25 Mo).
  static const Duration delaiEnvoi = Duration(seconds: 180);

  /// Redirection OAuth (Microsoft Entra ID) déclarée pour l'application.
  static const String redirectionMicrosoft = 'dgflowrcflutter://auth';

  static String get apiUrl {
    final brut = _apiUrlDefini.isNotEmpty
        ? _apiUrlDefini
        : (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        ? 'http://10.0.2.2:3000'
        : 'http://localhost:3000';
    return brut.endsWith('/') ? brut.substring(0, brut.length - 1) : brut;
  }

  /// URL affichée à l'utilisateur (sans le schéma).
  static String get serveurAffiche =>
      demo ? 'démonstration (hors ligne)' : apiUrl.replaceFirst(RegExp(r'^https?://'), '');

  /// `ios` | `android` | `web`, comme le contrat de l'API.
  static String get plateforme {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'web',
    };
  }
}
