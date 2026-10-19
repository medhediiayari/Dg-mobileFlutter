import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/session.dart';
import '../../core/models/models.dart';
import '../../core/providers.dart';

/// Pages chargées d'une liste (`/rc`), avec pagination infinie.
class EtatListe {
  const EtatListe({required this.pages, this.chargementSuite = false, this.erreurSuite});

  final List<ReponseListe> pages;
  final bool chargementSuite;
  final String? erreurSuite;

  ReponseListe get premiere => pages.first;
  List<ElementListe> get elements => [for (final p in pages) ...p.elements];
  bool get aSuivre => pages.last.aSuivre;

  EtatListe copie({List<ReponseListe>? pages, bool? chargementSuite, String? erreurSuite}) => EtatListe(
    pages: pages ?? this.pages,
    chargementSuite: chargementSuite ?? this.chargementSuite,
    erreurSuite: erreurSuite,
  );
}

class ListeNotifier extends AsyncNotifier<EtatListe> {
  ListeNotifier(this.filtres);

  final FiltresListe filtres;
  static const int limite = 25;

  @override
  Future<EtatListe> build() async {
    ref.watch(epoqueProvider);
    final page = await ref.watch(apiProvider).liste(filtres, page: 1, limite: limite);
    return EtatListe(pages: [page]);
  }

  /// Page suivante ; après un échec, seulement sur demande explicite ([force]).
  Future<void> chargerSuite({bool force = false}) async {
    final s = state.value;
    if (s == null || !s.aSuivre || s.chargementSuite || state.isLoading) return;
    if (s.erreurSuite != null && !force) return;
    state = AsyncData(s.copie(chargementSuite: true));
    try {
      final suite = await ref.read(apiProvider).liste(filtres, page: s.pages.last.page + 1, limite: limite);
      if (!ref.mounted) return;
      state = AsyncData(EtatListe(pages: [...s.pages, suite]));
    } catch (e) {
      if (!ref.mounted) return;
      state = AsyncData(s.copie(chargementSuite: false, erreurSuite: messageErreur(e)));
    }
  }
}

final listeProvider = AsyncNotifierProvider.autoDispose.family<ListeNotifier, EtatListe, FiltresListe>(
  ListeNotifier.new,
);

/// Fiche d'un document ; la garde de consultation y est mise à jour en place.
class DetailNotifier extends AsyncNotifier<Detail> {
  DetailNotifier(this.rcId);

  final int rcId;

  @override
  Future<Detail> build() {
    ref.watch(epoqueProvider);
    return ref.watch(apiProvider).detail(rcId);
  }

  /// Lecture enregistrée : nouvelle garde, sans relire toute la fiche.
  void majConsultation(Consultation c) {
    final d = state.value;
    if (d != null) state = AsyncData(d.avecConsultation(c));
  }
}

final detailProvider = AsyncNotifierProvider.autoDispose.family<DetailNotifier, Detail, int>(DetailNotifier.new);

final parcoursProvider = FutureProvider.autoDispose.family<Parcours, int>((ref, rcId) {
  ref.watch(epoqueProvider);
  return ref.watch(apiProvider).parcours(rcId);
});

final tableauProvider = FutureProvider.autoDispose.family<Tableau, int>((ref, rcId) {
  ref.watch(epoqueProvider);
  return ref.watch(apiProvider).tableau(rcId);
});

final fichiersProvider = FutureProvider.autoDispose.family<List<FichierDossier>, int>((ref, rcId) {
  ref.watch(epoqueProvider);
  return ref.watch(apiProvider).fichiers(rcId);
});

/// Après une décision (réussie ou non) : files, fiches, parcours et alertes sont
/// à relire. Prend le conteneur plutôt qu'un `WidgetRef` : la feuille de décision
/// peut avoir été fermée avant la réponse du serveur.
void invaliderApresDecision(ProviderContainer conteneur) {
  conteneur
    ..invalidate(listeProvider)
    ..invalidate(detailProvider)
    ..invalidate(parcoursProvider)
    ..invalidate(notificationsProvider)
    ..invalidate(nonLuesProvider);
}

// ─── Notifications ──────────────────────────────────────────────────────────

class EtatNotifications {
  const EtatNotifications({required this.elements, required this.suivant, this.chargementSuite = false});

  final List<NotificationRc> elements;
  final int? suivant;
  final bool chargementSuite;

  int get nonLues => elements.where((n) => !n.lue).length;
}

class NotificationsNotifier extends AsyncNotifier<EtatNotifications> {
  @override
  Future<EtatNotifications> build() async {
    ref.watch(epoqueProvider);
    final p = await ref.watch(apiProvider).notifications();
    return EtatNotifications(elements: p.elements, suivant: p.suivant);
  }

  Future<void> chargerSuite() async {
    final s = state.value;
    if (s == null || s.suivant == null || s.chargementSuite) return;
    state = AsyncData(EtatNotifications(elements: s.elements, suivant: s.suivant, chargementSuite: true));
    try {
      final p = await ref.read(apiProvider).notifications(avant: s.suivant);
      if (!ref.mounted) return;
      state = AsyncData(EtatNotifications(elements: [...s.elements, ...p.elements], suivant: p.suivant));
    } catch (_) {
      if (!ref.mounted) return;
      state = AsyncData(EtatNotifications(elements: s.elements, suivant: s.suivant));
    }
  }

  Future<void> marquerLue(int id) async {
    final s = state.value;
    if (s != null) {
      state = AsyncData(
        EtatNotifications(elements: [for (final n in s.elements) n.id == id ? n.marqueeLue() : n], suivant: s.suivant),
      );
    }
    try {
      await ref.read(apiProvider).marquerLue(id);
    } finally {
      if (ref.mounted) ref.invalidate(nonLuesProvider);
    }
  }

  Future<void> toutLire() async {
    final s = state.value;
    await ref.read(apiProvider).toutLire();
    if (!ref.mounted) return;
    if (s != null) {
      state = AsyncData(EtatNotifications(elements: [for (final n in s.elements) n.marqueeLue()], suivant: s.suivant));
    }
    ref.invalidate(nonLuesProvider);
  }
}

final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier, EtatNotifications>(
  NotificationsNotifier.new,
);

/// Compteur de non-lues (pastille de l'onglet Alertes), relu chaque minute.
final nonLuesProvider = FutureProvider<int>((ref) async {
  ref.watch(epoqueProvider);
  if (ref.watch(sessionProvider.select((s) => s.etat)) != EtatSession.connecte) return 0;
  final minuterie = Timer(const Duration(seconds: 60), ref.invalidateSelf);
  ref.onDispose(minuterie.cancel);
  return ref.watch(apiProvider).nonLues();
});

final sessionsAppareilsProvider = FutureProvider.autoDispose<List<SessionAppareil>>((ref) {
  ref.watch(epoqueProvider);
  return ref.watch(apiProvider).sessions();
});
