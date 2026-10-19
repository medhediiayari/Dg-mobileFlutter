import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/session.dart';
import '../core/models/commun.dart';
import '../features/accueil/accueil_screen.dart';
import '../features/alertes/alertes_screen.dart';
import '../features/auth/connexion_screen.dart';
import '../features/auth/indisponible_screen.dart';
import '../features/profil/profil_screen.dart';
import '../features/rc/fichiers_screen.dart';
import '../features/rc/fiche_screen.dart';
import '../features/rc/tableau_screen.dart';
import '../features/shell/coquille.dart';
import '../features/suivi/suivi_screen.dart';
import '../ui/widgets/composants.dart';

final GlobalKey<NavigatorState> cleNavigateurRacine = GlobalKey<NavigatorState>(debugLabel: 'racine');

const Set<String> _horsSession = {'/demarrage', '/connexion', '/indisponible'};

/// Routes de l'application. La session décide de l'écran : connexion, écran
/// d'indisponibilité ou application. Une adresse demandée avant la fin du
/// démarrage (lien profond) est rejouée une fois la session ouverte.
final routeurProvider = Provider<GoRouter>((ref) {
  final etat = ValueNotifier<EtatSession>(ref.read(sessionProvider).etat);
  ref.listen(sessionProvider.select((s) => s.etat), (_, e) => etat.value = e);
  String? cibleDifferee;

  late final GoRouter routeur;
  routeur = GoRouter(
    navigatorKey: cleNavigateurRacine,
    initialLocation: '/',
    refreshListenable: etat,
    redirect: (context, state) {
      final lieu = state.matchedLocation;
      switch (etat.value) {
        case EtatSession.chargement:
          if (!_horsSession.contains(lieu) && lieu != '/') cibleDifferee = state.uri.toString();
          return lieu == '/demarrage' ? null : '/demarrage';
        case EtatSession.deconnecte:
          return lieu == '/connexion' ? null : '/connexion';
        case EtatSession.horsLigne || EtatSession.miseAJour:
          return lieu == '/indisponible' ? null : '/indisponible';
        case EtatSession.connecte:
          if (_horsSession.contains(lieu)) {
            final cible = cibleDifferee;
            cibleDifferee = null;
            // L'adresse demandée s'empile au-dessus des onglets : « Retour » ramène à l'app.
            if (cible != null) WidgetsBinding.instance.addPostFrameCallback((_) => routeur.push(cible));
            return '/';
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: '/demarrage', builder: (_, _) => const DemarrageScreen()),
      GoRoute(path: '/connexion', builder: (_, _) => const ConnexionScreen()),
      GoRoute(path: '/indisponible', builder: (_, _) => const IndisponibleScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigation) => Coquille(navigation: navigation),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, _) => const AccueilScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/suivi',
                builder: (_, state) => SuiviScreen(bucketInitial: Bucket.depuis(state.uri.queryParameters['bucket'])),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/alertes', builder: (_, _) => const AlertesScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profil', builder: (_, _) => const ProfilScreen())],
          ),
        ],
      ),
      GoRoute(
        path: '/rc/:id',
        parentNavigatorKey: cleNavigateurRacine,
        builder: (_, state) => _avecId(state, (id) => FicheScreen(rcId: id)),
        routes: [
          GoRoute(
            path: 'tableau',
            parentNavigatorKey: cleNavigateurRacine,
            builder: (_, state) => _avecId(state, (id) => TableauScreen(rcId: id)),
          ),
          GoRoute(
            path: 'fichiers',
            parentNavigatorKey: cleNavigateurRacine,
            builder: (_, state) => _avecId(state, (id) => FichiersScreen(rcId: id)),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: const EtatVide(icone: Icons.wrong_location_outlined, titre: 'Page introuvable'),
    ),
  );
  ref.onDispose(() {
    routeur.dispose();
    etat.dispose();
  });
  return routeur;
});

Widget _avecId(GoRouterState state, Widget Function(int id) ecran) {
  final id = int.tryParse(state.pathParameters['id'] ?? '');
  if (id == null || id <= 0) {
    return Scaffold(
      appBar: AppBar(),
      body: const EtatVide(icone: Icons.search_off_rounded, titre: 'Document introuvable'),
    );
  }
  return ecran(id);
}
