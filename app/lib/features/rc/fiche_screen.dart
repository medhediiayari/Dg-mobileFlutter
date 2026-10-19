import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/dgflow_api.dart';
import '../../core/models/models.dart';
import '../../core/providers.dart';
import '../../core/utils/parcours.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/composants.dart';
import '../../ui/widgets/fil_parcours.dart';
import '../../ui/widgets/frise_parcours.dart';
import '../../ui/widgets/squelette.dart';
import 'decision/decision_sheet.dart';
import 'fiche_sections.dart';
import 'rc_providers.dart';

enum _Vue { fiche, parcours }

/// Fiche d'un RC / avenant : chiffres, garde « Avant de décider », documents,
/// parcours, et barre de décision collée en bas.
class FicheScreen extends ConsumerStatefulWidget {
  const FicheScreen({required this.rcId, super.key});

  final int rcId;

  @override
  ConsumerState<FicheScreen> createState() => _FicheScreenState();
}

class _FicheScreenState extends ConsumerState<FicheScreen> {
  _Vue _vue = _Vue.fiche;

  /// Lectures DOCUMENT enregistrées par cet écran.
  int _enregistrements = 0;
  bool _enregistrementEnCours = false;

  @override
  void initState() {
    super.initState();
    // Garde « on ne valide pas ce qu'on n'a pas lu » : la lecture du document
    // est enregistrée quand son contenu S'AFFICHE (pas au toucher de la carte),
    // puis à nouveau si le serveur la juge périmée (le document a bougé).
    ref.listenManual<AsyncValue<Detail>>(detailProvider(widget.rcId), (_, suivant) {
      if (suivant.hasValue && !suivant.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _enregistrerLecture());
      }
    }, fireImmediately: true);
  }

  void _enregistrerLecture() {
    if (!mounted || _enregistrementEnCours) return;
    final etat = ref.read(detailProvider(widget.rcId));
    final d = etat.value;
    if (d == null || etat.isLoading) return;
    if (_enregistrements > 0 && d.consultation.documentOk) return;
    if (_enregistrements >= 3) return;
    _enregistrements++;
    _enregistrementEnCours = true;
    ref
        .read(apiProvider)
        .enregistrerConsultation(widget.rcId, TypeConsultation.document)
        .then((c) {
          if (mounted) ref.read(detailProvider(widget.rcId).notifier).majConsultation(c);
        })
        .catchError((Object _) {})
        .whenComplete(() => _enregistrementEnCours = false);
  }

  /// Retour sur la fiche (tableau, fichiers…) : comme le focus d'écran du RN.
  Future<void> _ouvrir(String chemin) async {
    await context.push(chemin);
    if (mounted) _enregistrerLecture();
  }

  Future<void> _decider(Detail d, ModeDecision mode) async {
    await ouvrirDecision(context, d, mode, ouvrirTableau: () => _ouvrir('/rc/${d.id}/tableau'));
    if (mounted) _enregistrerLecture();
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(detailProvider(widget.rcId));
    final d = etat.value;

    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(d?.reference ?? 'Document', key: ValueKey(d?.reference)),
        ),
      ),
      bottomNavigationBar: d == null
          ? null
          : BarreDecision(
              d: d,
              onDecider: (mode) => _decider(d, mode),
              onOuvrirTableau: () => _ouvrir('/rc/${d.id}/tableau'),
            ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: d == null
            ? (etat.hasError
                  ? EtatErreur(
                      key: const ValueKey('erreur'),
                      message: messageErreur(etat.error),
                      icone: etat.error is ApiException && (etat.error as ApiException).code == 'RC_NOT_FOUND'
                          ? Icons.search_off_rounded
                          : Icons.cloud_off_rounded,
                      onReessayer: () => ref.invalidate(detailProvider(widget.rcId)),
                    )
                  : const SingleChildScrollView(key: ValueKey('squelette'), child: FicheSquelette()))
            : RefreshIndicator(
                key: const ValueKey('fiche'),
                onRefresh: () async {
                  ref.invalidate(parcoursProvider(widget.rcId));
                  try {
                    ref.invalidate(detailProvider(widget.rcId));
                    await ref.read(detailProvider(widget.rcId).future);
                  } catch (_) {}
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _EnTete(d: d)),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        Espace.l,
                        Espace.l,
                        Espace.l,
                        Espace.xxl + (_aUneBarre(d) ? 0 : MediaQuery.paddingOf(context).bottom),
                      ),
                      sliver: SliverList.list(
                        children: [
                          Segment<_Vue>(
                            options: const [(_Vue.fiche, 'Fiche'), (_Vue.parcours, 'Parcours')],
                            valeur: _vue,
                            onChange: (v) => setState(() => _vue = v),
                          ),
                          const SizedBox(height: Espace.l),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOut,
                            transitionBuilder: (enfant, a) => FadeTransition(
                              opacity: a,
                              child: SlideTransition(
                                position: Tween(begin: const Offset(0, 0.015), end: Offset.zero).animate(a),
                                child: enfant,
                              ),
                            ),
                            layoutBuilder: (courant, precedents) =>
                                Stack(alignment: Alignment.topCenter, children: [...precedents, ?courant]),
                            child: _vue == _Vue.fiche
                                ? ContenuFiche(key: const ValueKey('fiche'), d: d, onOuvrir: _ouvrir)
                                : _ContenuParcours(key: const ValueKey('parcours'), rcId: d.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// La barre de décision s'affiche-t-elle (elle gère alors la marge du bas) ?
bool _aUneBarre(Detail d) {
  final a = d.actions;
  return a.peutApprouver ||
      a.peutRejeter ||
      a.peutConvertirBc ||
      a.peutAnnulerBc ||
      a.peutRepondreInfo ||
      a.peutDemanderInfo;
}

class _EnTete extends StatelessWidget {
  const _EnTete({required this.d});

  final Detail d;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final pos = positionParcours(d.statut);
    final a = d.actions;
    final decideur = a.decideur;
    final phrase = decideur
        ? (pos.mode == ModeParcours.renvoi && pos.origine != null
              ? 'Renvoyé par le ${etapesCircuit[pos.origine!].sigle} : à vous de reprendre'
              : 'À vous de décider')
        : a.peutRepondreInfo
        ? 'Une information vous est demandée'
        : pos.phrase;
    final couleur = decideur || a.peutRepondreInfo
        ? (pos.mode == ModeParcours.renvoi ? p.alerte : p.action)
        : pos.mode == ModeParcours.termine
        ? p.succes
        : p.texteSecondaire;
    final lieu = [d.projet.nom, d.projet.ville].whereType<String>().where((s) => s.isNotEmpty).join(', ');

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.bordure)),
      ),
      padding: const EdgeInsets.fromLTRB(Espace.l, Espace.l, Espace.l, Espace.m + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Espace.s,
            runSpacing: Espace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TagType(avenant: d.estAvenant, numero: d.numeroAvenant, grand: true),
              Pastille(libelle: d.libelle, ton: d.ton, petite: true),
              if (d.estBc)
                const Pastille(
                  libelle: 'Bon de commande',
                  ton: Ton.alerte,
                  petite: true,
                  icone: Icons.receipt_long_rounded,
                ),
              if (d.version > 1) Text('version ${d.version}', style: Typo.petit.copyWith(color: p.texteSecondaire)),
            ],
          ),
          const SizedBox(height: Espace.s + 2),
          Text(d.intitule, style: Typo.titre.copyWith(color: p.texte)),
          const SizedBox(height: 3),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: d.projet.code ?? '—',
                  style: TextStyle(fontWeight: FontWeight.w600, color: p.texte),
                ),
                if (lieu.isNotEmpty) TextSpan(text: '  $lieu'),
              ],
            ),
            style: Typo.secondaire.copyWith(color: p.texteSecondaire),
          ),
          const SizedBox(height: Espace.l),
          FilParcours(statut: d.statut, grand: true, anime: true),
          const SizedBox(height: Espace.s + 2),
          Row(
            children: [
              if (decideur || a.peutRepondreInfo) ...[
                Icon(
                  a.peutRepondreInfo && !decideur
                      ? Icons.forum_rounded
                      : pos.mode == ModeParcours.renvoi
                      ? Icons.undo_rounded
                      : Icons.radio_button_checked_rounded,
                  size: 16,
                  color: couleur,
                ),
                const SizedBox(width: 6),
              ] else if (pos.mode == ModeParcours.termine) ...[
                Icon(Icons.verified_rounded, size: 17, color: couleur),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(phrase, style: Typo.libelle.copyWith(color: couleur)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContenuParcours extends ConsumerWidget {
  const _ContenuParcours({required this.rcId, super.key});

  final int rcId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parcours = ref.watch(parcoursProvider(rcId));
    return switch (parcours) {
      AsyncValue(:final value?) => Carte(
        child: FriseParcours(rcId: rcId, etapes: value.etapes),
      ),
      AsyncValue(:final error?) => EtatErreur(
        message: messageErreur(error),
        onReessayer: () => ref.invalidate(parcoursProvider(rcId)),
      ),
      _ => Miroitement(
        child: Carte(
          child: Column(
            children: [
              for (var i = 0; i < 4; i++)
                const Padding(
                  padding: EdgeInsets.only(bottom: Espace.l),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Os(largeur: 26, hauteur: 26, rayon: 13),
                      SizedBox(width: Espace.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [Os(facteur: 0.8, hauteur: 14), SizedBox(height: 6), Os(facteur: 0.5, hauteur: 11)],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    };
  }
}
