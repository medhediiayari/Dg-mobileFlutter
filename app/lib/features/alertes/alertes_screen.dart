import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

IconData _icone(NotificationRc n) {
  final t = n.type.toUpperCase();
  if (t.contains('INFO')) return Icons.forum_outlined;
  if (t.contains('REJECT') || t.contains('SENT_BACK')) return Icons.undo_rounded;
  if (t.contains('VALIDATED') || t.contains('APPROVED')) return Icons.check_circle_outline_rounded;
  if (t.contains('PROJECT')) return Icons.apartment_rounded;
  return Icons.description_outlined;
}

/// Notifications DG Flow du module RC (mêmes lignes que la cloche du web).
class AlertesScreen extends ConsumerWidget {
  const AlertesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.dg;
    final etat = ref.watch(notificationsProvider);
    final s = etat.value;
    final nonLues = s?.nonLues ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes'),
        automaticallyImplyLeading: false,
        titleSpacing: Espace.l,
        actions: [
          if (nonLues > 0)
            Padding(
              padding: const EdgeInsets.only(right: Espace.s),
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () async {
                  unawaited(HapticFeedback.selectionClick());
                  try {
                    await ref.read(notificationsProvider.notifier).toutLire();
                  } catch (e) {
                    if (context.mounted) signaler(context, messageErreur(e));
                  }
                },
                child: const Text('Tout marquer comme lu'),
              ),
            ),
        ],
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
                        icone: Icons.notifications_none_rounded,
                        titre: 'Aucune alerte',
                        texte: "Vous serez prévenu ici dès qu'un document arrive à votre étape ou vous est renvoyé.",
                      ),
                    ],
                  )
                : _Liste(etat: value, p: p),
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

class _Liste extends ConsumerWidget {
  const _Liste({required this.etat, required this.p});

  final EtatNotifications etat;
  final Palette p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupes = <String, List<NotificationRc>>{};
    for (final n in etat.elements) {
      groupes.putIfAbsent(jourNotification(n.le), () => []).add(n);
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(Espace.l, 0, Espace.l, Espace.xxl),
      children: [
        for (final MapEntry(key: jour, value: liste) in groupes.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: Espace.l, bottom: Espace.s, left: 2),
            child: Semantics(
              header: true,
              child: Text(jour, style: Typo.libelle.copyWith(color: p.texte)),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(Rayon.l),
              border: Border.all(color: p.bordure),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [for (final (i, n) in liste.indexed) _Ligne(n: n, derniere: i == liste.length - 1)],
            ),
          ),
        ],
        if (etat.chargementSuite)
          const Padding(
            padding: EdgeInsets.all(Espace.l),
            child: Center(child: Roue()),
          ),
      ],
    );
  }
}

class _Ligne extends ConsumerWidget {
  const _Ligne({required this.n, required this.derniere});

  final NotificationRc n;
  final bool derniere;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.dg;
    return Semantics(
      button: true,
      label: '${n.lue ? '' : 'Non lue. '}${n.titre}. ${n.message}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () {
          if (!n.lue) ref.read(notificationsProvider.notifier).marquerLue(n.id).catchError((Object _) {});
          if (n.rcId != null) context.push('/rc/${n.rcId}');
        },
        child: Container(
          decoration: BoxDecoration(
            border: derniere ? null : Border(bottom: BorderSide(color: p.bordure)),
          ),
          padding: const EdgeInsets.fromLTRB(Espace.m, Espace.m, Espace.m, Espace.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: n.lue ? p.neutreFond : p.accentClair,
                      borderRadius: BorderRadius.circular(Rayon.m),
                    ),
                    child: Icon(_icone(n), size: 20, color: n.lue ? p.texteTertiaire : p.action),
                  ),
                  if (!n.lue)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: p.action,
                          shape: BoxShape.circle,
                          border: Border.all(color: p.surface, width: 2),
                        ),
                      ),
                    ),
                ],
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
                            style: Typo.corpsFort.copyWith(
                              color: n.lue ? p.texteSecondaire : p.texte,
                              fontWeight: n.lue ? FontWeight.w500 : FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: Espace.s),
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(_heure(n.le), style: Typo.petit.copyWith(color: p.texteTertiaire)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      n.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Typo.secondaire.copyWith(color: n.lue ? p.texteSecondaire : p.texte),
                    ),
                  ],
                ),
              ),
              if (n.rcId != null)
                Padding(
                  padding: const EdgeInsets.only(left: Espace.xs, top: 8),
                  child: Icon(Icons.chevron_right_rounded, size: 20, color: p.texteTertiaire),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
