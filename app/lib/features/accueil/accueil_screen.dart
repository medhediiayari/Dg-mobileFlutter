import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/session.dart';
import '../../core/config/app_config.dart';
import '../../core/models/models.dart';
import '../../core/utils/format.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/carte_rc.dart';
import '../../ui/widgets/composants.dart';
import '../../ui/widgets/marque.dart';
import '../../ui/widgets/selecteur_role.dart';
import '../../ui/widgets/squelette.dart';
import '../rc/rc_providers.dart';

/// Phrase d'accueil : où en suis-je ?
String phraseAccueil(String? etape, int n) {
  if (etape == 'RP') {
    return n == 0 ? 'Aucun document à finaliser' : (n == 1 ? 'Un document à finaliser' : '$n documents à finaliser');
  }
  if (etape == null) return 'Suivi des RC et avenants';
  if (n == 0) return "Rien n'attend votre décision";
  return n == 1 ? 'Un document attend votre décision' : '$n documents attendent votre décision';
}

/// File « À traiter » du rôle actif.
class AccueilScreen extends ConsumerStatefulWidget {
  const AccueilScreen({super.key});

  @override
  ConsumerState<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends ConsumerState<AccueilScreen> {
  final _defilement = ScrollController();
  bool _compact = false;

  @override
  void initState() {
    super.initState();
    _defilement.addListener(() {
      final compact = _defilement.hasClients && _defilement.offset > 150;
      if (compact != _compact) setState(() => _compact = compact);
    });
  }

  @override
  void dispose() {
    _defilement.dispose();
    super.dispose();
  }

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
    final etape = profil?.roleActif.etape;
    final phrase = premiere == null ? 'Chargement…' : phraseAccueil(etape, premiere.total);

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
              controller: _defilement,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: p.marine,
                  automaticallyImplyLeading: false,
                  titleSpacing: Espace.l,
                  title: Row(
                    children: [
                      if (profil != null)
                        Flexible(
                          child: Align(alignment: Alignment.centerLeft, child: _PiluleRole()),
                        ),
                      const SizedBox(width: Espace.s),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _compact && premiere != null
                            ? Text(
                                '${premiere.total} à traiter',
                                key: const ValueKey('compact'),
                                style: Typo.sousTitre.copyWith(color: p.surMarine, fontSize: 18),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: _EnTete(phrase: phrase, premiere: premiere),
                ),
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
                ton: Ton.alerte,
                icone: Icons.mark_email_unread_outlined,
                titre: '${Format.pluriel(premiere.enAttenteReception, 'projet')} sans accusé de réception',
                child: Text(
                  'Confirmez la réception sur DG Flow web pour voir leurs RC ici.',
                  style: Typo.secondaire.copyWith(color: p.texte),
                ),
              ),
            if (profil?.lectureSeule == true && profil?.motifLectureSeule != null)
              Bandeau(
                ton: Ton.neutre,
                icone: Icons.visibility_outlined,
                titre: 'Consultation',
                child: Text(profil!.motifLectureSeule!, style: Typo.secondaire.copyWith(color: p.texte)),
              ),
          ],
        ),
      ),
      if (elements.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: EtatVide(
            icone: Icons.task_alt_rounded,
            titre: profil?.roleActif.etape == 'RP' ? 'Tout est à jour' : 'Vous êtes à jour',
            texte: profil?.roleActif.etape == 'RP'
                ? 'Aucun brouillon ni RC renvoyé pour correction.'
                : 'Les documents qui arrivent à votre étape apparaîtront ici, avec une notification.',
            action: OutlinedButton(onPressed: () => context.go('/suivi'), child: const Text('Voir le suivi')),
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

class _PiluleRole extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.dg;
    final profil = ref.watch(profilProvider)!;
    final plusieurs = profil.plusieursRoles;
    final r = profil.roleActif;
    return Semantics(
      button: plusieurs,
      label: 'Rôle actif : ${r.libelle}${plusieurs ? '. Changer de rôle' : ''}',
      excludeSemantics: true,
      child: ZoneTactile(
        onTap: plusieurs ? () => ouvrirSelecteurRole(context) : null,
        child: Material(
          color: Colors.white.withValues(alpha: 0.10),
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: plusieurs ? () => ouvrirSelecteurRole(context) : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: p.chevronProfond, borderRadius: BorderRadius.circular(999)),
                      child: Text(r.monogramme, style: Typo.sigle.copyWith(color: Colors.white, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        r.libelle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Typo.libelle.copyWith(color: p.surMarineDoux, fontSize: 14),
                      ),
                    ),
                    if (plusieurs) ...[
                      const SizedBox(width: 2),
                      Icon(Icons.expand_more_rounded, size: 18, color: p.surMarineDoux),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EnTete extends ConsumerWidget {
  const _EnTete({required this.phrase, required this.premiere});

  final String phrase;
  final ReponseListe? premiere;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.dg;
    final r = premiere;
    final info = r?.compteurs.infoPourMoi ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: p.marine,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Rayon.xl + 6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: ChevronsFiligrane()),
          Padding(
            padding: const EdgeInsets.fromLTRB(Espace.l, Espace.xs, Espace.l, Espace.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (AppConfig.demo) ...[const BandeauDemo(), const SizedBox(height: Espace.m)],
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      phrase,
                      key: ValueKey(phrase),
                      style: Typo.affiche.copyWith(color: p.surMarine),
                    ),
                  ),
                ),
                if (info > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'dont ${Format.pluriel(info, "demande")} d’information',
                      style: Typo.corps.copyWith(color: p.surMarineDoux, fontWeight: FontWeight.w500),
                    ),
                  ),
                const SizedBox(height: Espace.l + 2),
                _Compteurs(r: r),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Compteurs extends StatelessWidget {
  const _Compteurs({required this.r});

  final ReponseListe? r;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
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
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Rayon.m + 2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(Rayon.m + 2),
                  onTap: () => context.go('/suivi?bucket=${bucket.name}'),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Espace.m, Espace.s + 2, Espace.s, Espace.s + 2),
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
                                  ? const Color(0xFFF6C28B)
                                  : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          libelle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Typo.petit.copyWith(color: p.surMarineDoux, fontSize: 13),
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
