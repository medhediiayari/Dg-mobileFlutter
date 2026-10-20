import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/session.dart';
import '../../core/config/app_config.dart';
import '../../core/models/models.dart';
import '../../core/utils/format.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/carte_rc.dart';
import '../../ui/widgets/composants.dart';
import '../../ui/widgets/marque.dart';
import '../../ui/widgets/squelette.dart';
import '../rc/rc_providers.dart';

/// File « À traiter » du rôle actif.
class AccueilScreen extends ConsumerStatefulWidget {
  const AccueilScreen({super.key});

  @override
  ConsumerState<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends ConsumerState<AccueilScreen> {
  Future<void> _rafraichir() async {
    try {
      ref.invalidate(listeProvider(FiltresListe.aTraiter));
      await ref.read(listeProvider(FiltresListe.aTraiter).future);
    } catch (_) {
      // L'erreur s'affiche dans la liste.
    }
    ref.invalidate(nonLuesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final profil = ref.watch(profilProvider);
    final liste = ref.watch(listeProvider(FiltresListe.aTraiter));
    final premiere = liste.value?.premiere;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.extentAfter < 500) ref.read(listeProvider(FiltresListe.aTraiter).notifier).chargerSuite();
            return false;
          },
          child: RefreshIndicator(
            onRefresh: _rafraichir,
            edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: p.marineProfond,
                  automaticallyImplyLeading: false,
                  titleSpacing: Espace.l,
                  title: const Align(alignment: Alignment.centerLeft, child: LogoDgFlow(hauteur: 20, surFonce: true)),
                ),
                SliverToBoxAdapter(child: _EnTete(premiere: premiere)),
                ..._contenu(context, liste, profil),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _contenu(BuildContext context, AsyncValue<EtatListe> liste, Profil? profil) {
    final p = context.dg;
    if (liste.hasError && !liste.hasValue) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EtatErreur(
            message: messageErreur(liste.error),
            onReessayer: () => ref.invalidate(listeProvider(FiltresListe.aTraiter)),
          ),
        ),
      ];
    }
    final s = liste.value;
    if (s == null) return const [SliverToBoxAdapter(child: ListeSquelette())];
    final premiere = s.premiere;
    final elements = s.elements;
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(Espace.l, Espace.l, Espace.l, 0),
        sliver: SliverList.list(
          children: [
            if (premiere.enAttenteReception > 0)
              Bandeau(
                teinte: p.ambre,
                icone: LucideIcons.mailWarning,
                titre: '${Format.pluriel(premiere.enAttenteReception, 'projet')} sans accusé de réception',
                child: const Text('Confirmez la réception sur DG Flow web pour voir leurs RC ici.'),
              ),
          ],
        ),
      ),
      if (elements.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: EtatVide(
              icone: LucideIcons.checkCircle,
              titre: profil?.roleActif.etape == 'RP' ? 'Tout est à jour' : 'Vous êtes à jour',
              texte: profil?.roleActif.etape == 'RP'
                  ? 'Aucun brouillon ni RC renvoyé pour correction.'
                  : 'Les documents qui arrivent à votre étape apparaîtront ici, avec une notification.',
              action: OutlinedButton(onPressed: () => context.go('/suivi'), child: const Text('Voir le suivi')),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(Espace.l, 0, Espace.l, Espace.xxl),
          sliver: SliverList.builder(
            itemCount: elements.length + (s.chargementSuite ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= elements.length) return const Miroitement(child: CarteSquelette());
              final rc = elements[i];
              return CarteRc(rc: rc, onTap: () => context.push('/rc/${rc.id}'));
            },
          ),
        ),
    ];
  }
}

class _EnTete extends StatelessWidget {
  const _EnTete({required this.premiere});

  final ReponseListe? premiere;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    // Bandeau d'indicateurs des tableaux de bord du web : `bg-[#162c4b] px-6 pt-5 pb-5`.
    return ColoredBox(
      color: p.marineProfond,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Espace.l, Espace.xs, Espace.l, Espace.l + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (AppConfig.demo) ...[const BandeauDemo(), const SizedBox(height: Espace.m)],
            _Compteurs(r: premiere),
          ],
        ),
      ),
    );
  }
}

/// Tuiles d'indicateurs : `rounded-xl border border-white/20 bg-white/10 px-4 py-3`,
/// valeur `text-2xl font-bold text-white`, libellé `text-sm font-semibold text-white/90`.
class _Compteurs extends StatelessWidget {
  const _Compteurs({required this.r});

  final ReponseListe? r;

  @override
  Widget build(BuildContext context) {
    const raccourcis = [(Bucket.pending, 'En attente'), (Bucket.rejected, 'Renvoyés'), (Bucket.approved, 'Validés')];
    return Row(
      children: [
        for (final (i, (bucket, libelle)) in raccourcis.indexed) ...[
          if (i > 0) const SizedBox(width: Espace.s),
          Expanded(
            child: Semantics(
              button: true,
              label: '$libelle : ${r?.compteurs[bucket] ?? '…'}. Ouvrir le suivi',
              excludeSemantics: true,
              child: Material(
                color: Colors.white.withValues(alpha: 0.10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Rayon.l),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.20)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(Rayon.l),
                  onTap: () => context.go('/suivi?bucket=${bucket.name}'),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Espace.m, Espace.m, Espace.s, Espace.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            r == null ? '–' : '${r!.compteurs[bucket]}',
                            key: ValueKey('${bucket.name}-${r?.compteurs[bucket]}'),
                            style: Typo.compteur.copyWith(
                              color: bucket == Bucket.rejected && (r?.compteurs[bucket] ?? 0) > 0
                                  ? Tw.orange300
                                  : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          libelle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Typo.libelle.copyWith(color: Colors.white.withValues(alpha: 0.90)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
