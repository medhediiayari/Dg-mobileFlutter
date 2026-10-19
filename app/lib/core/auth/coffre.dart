import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Clés persistées sur le téléphone.
abstract final class Cles {
  static const String jetons = 'dgflow-rc.jetons';
  static const String installation = 'dgflow-rc.installation';
  static const String dernierEmail = 'dgflow-rc.dernier-email';
  static const String apparence = 'dgflow-rc.apparence';
}

/// Stockage clé / valeur (Keychain iOS, Keystore Android).
abstract interface class Coffre {
  Future<String?> lire(String cle);
  Future<void> ecrire(String cle, String valeur);
  Future<void> effacer(String cle);
}

class CoffreSecurise implements Coffre {
  CoffreSecurise([FlutterSecureStorage? stockage])
    : _stockage =
          stockage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
          );

  final FlutterSecureStorage _stockage;

  @override
  Future<String?> lire(String cle) async {
    try {
      return await _stockage.read(key: cle);
    } catch (_) {
      // Coffre illisible (restauration de sauvegarde, clé changée) : on repart de zéro.
      return null;
    }
  }

  @override
  Future<void> ecrire(String cle, String valeur) => _stockage.write(key: cle, value: valeur);

  @override
  Future<void> effacer(String cle) => _stockage.delete(key: cle);
}

/// Coffre en mémoire : mode démonstration et tests.
class CoffreMemoire implements Coffre {
  CoffreMemoire([Map<String, String>? initial]) : valeurs = {...?initial};

  final Map<String, String> valeurs;

  @override
  Future<String?> lire(String cle) async => valeurs[cle];

  @override
  Future<void> ecrire(String cle, String valeur) async => valeurs[cle] = valeur;

  @override
  Future<void> effacer(String cle) async => valeurs.remove(cle);
}

/// Jeton d'accès court + jeton de rafraîchissement à rotation.
class Jetons {
  const Jetons({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  String encoder() => jsonEncode({'accessToken': accessToken, 'refreshToken': refreshToken});

  static Jetons? decoder(String? brut) {
    if (brut == null || brut.isEmpty) return null;
    try {
      final j = jsonDecode(brut) as Map<String, dynamic>;
      final a = j['accessToken'] as String?;
      final r = j['refreshToken'] as String?;
      return a == null || r == null ? null : Jetons(accessToken: a, refreshToken: r);
    } catch (_) {
      return null;
    }
  }
}
