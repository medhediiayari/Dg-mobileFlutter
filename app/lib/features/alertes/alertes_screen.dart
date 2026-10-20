import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/models.dart';
import '../../core/utils/format.dart';
import '../../ui/dialogues.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/composants.dart';
import '../../ui/widgets/squelette.dart';
import '../rc/rc_providers.dart';

/// Libellé du jour d'une notification, pour les regrouper.
String jourNotification(DateTime d, {DateTime? maintenant}) {
  final m = maintenant ?? DateTime.now();
  final minuit = DateTime(m.year, m.month, m.day);
  final jour = DateTime(d.year, d.month, d.day);
  final ecart = minuit.difference(jour).inDays;
  if (ecart <= 0) return "Aujourd'hui";
  if (ecart == 1) return 'Hier';
  if (ecart < 7) return 'Cette semaine';
  return 'Plus ancien';
}

String _heure(DateTime d) {
  final m = DateTime.now();
  final aujourdhui = d.year == m.year && d.month == m.month && d.day == m.day;
  return aujourdhui ? Format.heure(d) : Format.jourMois(d);
}

/// Puce de type de la cloche du web (`NotificationBell.tsx`) : information ambre,
/// rejet rouge, approbation verte, signature indigo, soumission ambre (jaune sur le web).
({IconData icone, Teinte teinte}) _type(BuildContext context, NotificationRc n) {
  final p = context.dg;
  // Familles de types de `lib/notification-service.ts`, par préfixe : `RC_APPROVED_INFO`
  // est une approbation et `RC_PROJECT_ASSIGNED` une affectation (pas de recherche de
  // sous-chaîne « INFO » ou « SIGN »).
  final t = n.type.toUpperCase();
  bool famille(String f) => t == f || t.startsWith('${f}_');
  if (famille('RC_INFO')) return (icone: LucideIcons.messageCircleQuestion, teinte: p.ambre);
  if (famille('RC_REJECTED') || famille('RC_SENT_BACK')) return (icone: LucideIcons.xCircle, teinte: p.rouge);
  if (famille('RC_APPROVED') || famille('RC_VALIDATED')) return (icone: LucideIcons.checkCircle, teinte: p.vert);
  if (famille('RC_SIGNED') || famille('RC_CONTRACT')) return (icone: LucideIcons.signature, teinte: p.indigo);
  if (famille('RC_SUBMITTED')) return (icone: LucideIcons.send, teinte: p.ambre);
  if (famille('PROJECT') || famille('RC_PROJECT')) return (icone: LucideIcons.building2, teinte: p.gris);
  return (icone: LucideIcons.fileText, teinte: p.bleu);
}

/// Initiales de l'auteur pour l'avatar (`size-9`, repli `bg-gray-100 text-xs font-semibold`).
String? _initiales(String? nom) {
  final mots = (nom ?? '').trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty).toList();
  if (mots.isEmpty) return null;
  final i = mots.length == 1 ? mots.first[0] : '${mots.first[0]}${mots.last[0]}';
  return i.toUpperCase();
}

/// Notifications DG Flow du module RC (mêmes lignes que la cloche du web).
class AlertesScreen extends ConsumerWidget {
  const AlertesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes'),
        flexibleSpace: const DegradeEnTete(),
        automaticallyImplyLeading: false,
        titleSpacing: Espace.l,
      ),
      body: switch (etat) {
        AsyncValue(:final value?) => NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.extentAfter < 400) ref.read(notificationsProvider.notifier).chargerSuite();
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(nonLuesProvider);
              try {
                ref.invalidate(notificationsProvider);
                await ref.read(notificationsProvider.future);
              } catch (_) {}
            },
            child: value.elements.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      EtatVide(
                        icone: LucideIcons.bellOff,
                        titre: 'Aucune alerte',
                        texte: "Vous serez prévenu ici dès qu'un document arrive à votre étape ou vous est renvoyé.",
                      ),
                    ],
                  )
                : _Liste(etat: value),
          ),
        ),
        AsyncValue(:final error?) => EtatErreur(
          message: messageErreur(error),
          onReessayer: () => ref.invalidate(notificationsProvider),
        ),
        _ => const SingleChildScrollView(child: ListeSquelette(nombre: 4)),
      },
    );
  }
}

/// Panneau de la cloche du web : `rounded-xl border border-gray-200 bg-white`,
/// en-têtes de groupe `text-[11px] font-semibold tracking-wide text-gray-500 bg-gray-50`.
class _Liste extends ConsumerWidget {
  const _Liste({required this.etat});

  final EtatNotifications etat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.dg;
    final groupes = <String, List<NotificationRc>>{};
    for (final n in etat.elements) {
      groupes.putIfAbsent(jourNotification(n.le), () => []).add(n);
    }
    final entrees = groupes.entries.toList();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(Espace.l, Espace.s, Espace.l, Espace.xxl),
      children: [
        _BarreLecture(nonLues: etat.nonLues),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Rayon.l),
            boxShadow: context.sombre ? null : OmbreWeb.sm,
          ),
          child: Material(
            color: p.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Rayon.l),
              side: BorderSide(color: p.bordure),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (g, MapEntry(key: jour, value: liste)) in entrees.indexed) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: Espace.l, vertical: Espace.s),
                    decoration: BoxDecoration(
                      color: p.gris.fondDoux,
                      border: Border(
                        top: g == 0 ? BorderSide.none : BorderSide(color: p.bordure),
                        bottom: BorderSide(color: p.bordure),
                      ),
                    ),
                    child: Semantics(
                      header: true,
                      child: Text(jour, style: Typo.surTitre.copyWith(color: p.texteTertiaire)),
                    ),
                  ),
                  for (final (i, n) in liste.indexed) _Ligne(n: n, derniere: i == liste.length - 1),
                ],
              ],
            ),
          ),
        ),
        if (etat.chargementSuite)
          const Padding(
            padding: EdgeInsets.all(Espace.l),
            child: Center(child: Roue()),
          ),
      ],
    );
  }
}

/// « {n} non lues » et « Tout marquer comme lu » (lien `text-[#0061A7]`).
class _BarreLecture extends ConsumerWidget {
  const _BarreLecture({required this.nonLues});

  final int nonLues;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.dg;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                nonLues == 0 ? 'Tout est lu' : (nonLues == 1 ? '1 non lue' : '$nonLues non lues'),
                style: Typo.libelle.copyWith(color: p.texteSecondaire),
              ),
            ),
          ),
          if (nonLues > 0)
            TextButton.icon(
              onPressed: () async {
                unawaited(HapticFeedback.selectionClick());
                try {
                  await ref.read(notificationsProvider.notifier).toutLire();
                } catch (e) {
                  if (context.mounted) signaler(context, messageErreur(e), icone: LucideIcons.xCircle, teinte: p.rouge);
                }
              },
              icon: const Icon(LucideIcons.checkCheck, size: 16),
              label: const Text('Tout marquer comme lu'),
            ),
        ],
      ),
    );
  }
}

/// Ligne de notification : non lue `bg-blue-50/50` + barre gauche `w-[3px] bg-blue-500`,
/// avatar `size-9` avec puce de type en bas à droite (`h-5 w-5 rounded-full ring-2 ring-white`).
class _Ligne extends ConsumerWidget {
  const _Ligne({required this.n, required this.derniere});

  final NotificationRc n;
  final bool derniere;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.dg;
    final type = _type(context, n);
    final initiales = _initiales(n.acteur);
    return Semantics(
      button: true,
      label: '${n.lue ? '' : 'Non lue. '}${n.titre}. ${n.message}',
      excludeSemantics: true,
      child: Material(
        color: n.lue ? p.surface : Color.alphaBlend(p.bleu.fondDoux.withValues(alpha: 0.5), p.surface),
        child: InkWell(
          onTap: () {
            if (!n.lue) ref.read(notificationsProvider.notifier).marquerLue(n.id).catchError((Object _) {});
            if (n.rcId != null) context.push('/rc/${n.rcId}');
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: n.lue ? Colors.transparent : p.bleu.plein, width: 3),
                bottom: derniere ? BorderSide.none : BorderSide(color: p.bordure),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(Espace.m + 1, Espace.m, Espace.m, Espace.m),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: p.gris.fond, shape: BoxShape.circle),
                        child: initiales == null
                            ? Icon(type.icone, size: 18, color: p.gris.vif)
                            : Text(
                                initiales,
                                style: Typo.petit.copyWith(color: p.gris.vif, fontWeight: FontWeight.w600),
                              ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: type.teinte.fond,
                            shape: BoxShape.circle,
                            border: Border.all(color: p.surface, width: 2),
                          ),
                          child: Icon(type.icone, size: 11, color: type.teinte.texte),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Espace.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              n.titre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Typo.libelle.copyWith(
                                fontSize: 14.5,
                                color: n.lue ? p.texteSecondaire : p.texte,
                                fontWeight: n.lue ? FontWeight.w500 : FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: Espace.s),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(_heure(n.le), style: Typo.petit.copyWith(color: p.texteTertiaire)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        n.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Typo.secondaire.copyWith(color: p.texteSecondaire),
                      ),
                    ],
                  ),
                ),
                if (n.rcId != null)
                  Padding(
                    padding: const EdgeInsets.only(left: Espace.xs, top: 8),
                    child: Icon(LucideIcons.chevronRight, size: 18, color: p.texteDiscret),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
