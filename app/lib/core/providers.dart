import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/dgflow_api.dart';
import 'auth/coffre.dart';
import 'auth/microsoft.dart';
import 'push/service_push.dart';

/// Informations sur l'application installée.
class InfosApp {
  const InfosApp({required this.version, required this.nomAppareil});

  /// Version « x.y.z », comparée à `/meta.versionMinimaleApp`.
  final String version;

  /// « Google Pixel 8 », transmis à la connexion (écran « Appareils connectés »).
  final String nomAppareil;
}

/// API (réelle ou démonstration) — fournie par `main.dart`.
final apiProvider = Provider<DgFlowApi>((ref) => throw UnimplementedError('apiProvider non fourni'));

final coffreProvider = Provider<Coffre>((ref) => throw UnimplementedError('coffreProvider non fourni'));

final infosAppProvider = Provider<InfosApp>((ref) => const InfosApp(version: '1.0.0', nomAppareil: 'Téléphone'));

final pushProvider = Provider<ServicePush>((ref) => ServicePush(coffre: ref.watch(coffreProvider)));

final microsoftProvider = Provider<ConnexionMicrosoft>((ref) => const ConnexionMicrosoft());

/// Apparence choisie dans le profil (système par défaut).
class ApparenceNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    Future.microtask(_charger);
    return ThemeMode.system;
  }

  Future<void> _charger() async {
    final v = await ref.read(coffreProvider).lire(Cles.apparence);
    final mode = ThemeMode.values.where((m) => m.name == v).firstOrNull;
    if (mode != null && ref.mounted) state = mode;
  }

  Future<void> choisir(ThemeMode mode) async {
    state = mode;
    await ref.read(coffreProvider).ecrire(Cles.apparence, mode.name);
  }
}

final apparenceProvider = NotifierProvider<ApparenceNotifier, ThemeMode>(ApparenceNotifier.new);
