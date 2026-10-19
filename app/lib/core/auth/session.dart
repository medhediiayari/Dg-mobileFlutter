import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exception.dart';
import '../config/app_config.dart';
import '../models/profil.dart';
import '../providers.dart';
import '../utils/format.dart';
import 'coffre.dart';

enum EtatSession { chargement, deconnecte, connecte, horsLigne, miseAJour }

class EtatApp {
  const EtatApp({required this.etat, this.profil, this.meta, this.erreurDemarrage, this.epoque = 0});

  final EtatSession etat;
  final Profil? profil;
  final Meta? meta;
  final String? erreurDemarrage;

  /// Change à chaque connexion, déconnexion ou changement de rôle : toutes les
  /// données (files, compteurs, droits) en dépendent et sont relues.
  final int epoque;

  EtatApp copie({
    EtatSession? etat,
    Profil? profil,
    bool sansProfil = false,
    Meta? meta,
    String? erreur,
    int? epoque,
  }) => EtatApp(
    etat: etat ?? this.etat,
    profil: sansProfil ? null : (profil ?? this.profil),
    meta: meta ?? this.meta,
    erreurDemarrage: erreur,
    epoque: epoque ?? this.epoque,
  );
}

/// Session : démarrage (meta, version minimale, jetons, profil), connexion,
/// déconnexion, rôle actif. Équivalent de `mobile/src/auth/session.tsx`.
class SessionNotifier extends Notifier<EtatApp> {
  @override
  EtatApp build() {
    final api = ref.watch(apiProvider);
    api.surSessionExpiree = _sessionPerdue;
    Future.microtask(demarrer);
    return const EtatApp(etat: EtatSession.chargement);
  }

  void _sessionPerdue() {
    if (state.etat == EtatSession.deconnecte) return;
    state = state.copie(etat: EtatSession.deconnecte, sansProfil: true, epoque: state.epoque + 1);
  }

  Future<void> demarrer() async {
    final api = ref.read(apiProvider);
    state = state.copie(etat: EtatSession.chargement);
    Meta? meta;
    try {
      meta = await api.meta();
      if (Format.versionInferieure(ref.read(infosAppProvider).version, meta.versionMinimaleApp)) {
        state = state.copie(etat: EtatSession.miseAJour, meta: meta);
        return;
      }
      if (!await api.restaurerSession()) {
        state = state.copie(etat: EtatSession.deconnecte, meta: meta, sansProfil: true);
        return;
      }
      final profil = await api.moi();
      state = EtatApp(etat: EtatSession.connecte, profil: profil, meta: meta, epoque: state.epoque + 1);
      unawaited(ref.read(pushProvider).activer(api));
    } on ApiException catch (e) {
      state = e.reseau
          ? state.copie(etat: EtatSession.horsLigne, meta: meta, erreur: e.message)
          : state.copie(etat: EtatSession.deconnecte, meta: meta, sansProfil: true);
    } catch (_) {
      state = state.copie(etat: EtatSession.deconnecte, meta: meta, sansProfil: true);
    }
  }

  Future<void> _ouvrir(ReponseConnexion r) async {
    state = EtatApp(etat: EtatSession.connecte, profil: r.utilisateur, meta: state.meta, epoque: state.epoque + 1);
    unawaited(ref.read(pushProvider).activer(ref.read(apiProvider)));
  }

  Future<void> connexion(String email, String motDePasse) async {
    final infos = ref.read(infosAppProvider);
    final r = await ref
        .read(apiProvider)
        .connexion(
          email: email.trim(),
          motDePasse: motDePasse,
          appareil: infos.nomAppareil,
          plateforme: AppConfig.plateforme,
        );
    await ref.read(coffreProvider).ecrire(Cles.dernierEmail, email.trim());
    await _ouvrir(r);
  }

  Future<void> connexionMicrosoft(String jetonGraph) async {
    final infos = ref.read(infosAppProvider);
    final r = await ref
        .read(apiProvider)
        .connexionMicrosoft(accessToken: jetonGraph, appareil: infos.nomAppareil, plateforme: AppConfig.plateforme);
    await _ouvrir(r);
  }

  Future<void> deconnexion() async {
    final api = ref.read(apiProvider);
    await ref.read(pushProvider).desactiver(api);
    await api.deconnexion();
    state = state.copie(etat: EtatSession.deconnecte, sansProfil: true, epoque: state.epoque + 1);
  }

  Future<void> changerRole(int roleId) async {
    final profil = await ref.read(apiProvider).changerRole(roleId);
    // Files, compteurs et droits dépendent du rôle actif : tout est à relire.
    state = state.copie(profil: profil, epoque: state.epoque + 1);
  }

  /// Profil relu (après un refus 403 de rôle par exemple).
  Future<void> rafraichirProfil() async {
    final profil = await ref.read(apiProvider).moi();
    state = state.copie(profil: profil);
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, EtatApp>(SessionNotifier.new);

/// Profil connecté (null hors session).
final profilProvider = Provider<Profil?>((ref) => ref.watch(sessionProvider.select((s) => s.profil)));

/// Époque de session : à surveiller par toute donnée dépendant de l'utilisateur ou du rôle.
final epoqueProvider = Provider<int>((ref) => ref.watch(sessionProvider.select((s) => s.epoque)));
