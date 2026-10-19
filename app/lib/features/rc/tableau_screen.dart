import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/dgflow_api.dart';
import '../../core/models/models.dart';
import '../../core/providers.dart';
import '../../core/utils/format.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/composants.dart';
import '../../ui/widgets/squelette.dart';
import 'rc_providers.dart';

/// Tableau chiffré en lecture : comparatif (RC) ou explicatif (avenant).
/// Son affichage vaut lecture du tableau (garde B) — une fois pour la vie du document.
class TableauScreen extends ConsumerStatefulWidget {
  const TableauScreen({required this.rcId, super.key});

  final int rcId;

  @override
  ConsumerState<TableauScreen> createState() => _TableauScreenState();
}

class _TableauScreenState extends ConsumerState<TableauScreen> {
  bool _demande = false;
  bool _enregistre = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<Tableau>>(tableauProvider(widget.rcId), (_, t) {
      final v = t.value;
      if (v != null && v is! TableauAbsent && !_demande) {
        _demande = true;
        // Enregistré quand le tableau S'AFFICHE, comme sur le web.
        WidgetsBinding.instance.addPostFrameCallback((_) => _enregistrer());
      }
    }, fireImmediately: true);
  }

  Future<void> _enregistrer() async {
    if (!mounted) return;
    try {
      final c = await ref.read(apiProvider).enregistrerConsultation(widget.rcId, TypeConsultation.tableau);
      if (!mounted) return;
      if (ref.exists(detailProvider(widget.rcId))) {
        ref.read(detailProvider(widget.rcId).notifier).majConsultation(c);
      }
      setState(() => _enregistre = true);
    } catch (_) {
      // La fiche relira la garde ; la décision la revérifiera de toute façon.
    }
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(tableauProvider(widget.rcId));
    final t = etat.value;
    final titre = switch (t) {
      TableauComparatif() => 'Tableau comparatif',
      TableauExplicatif() => 'Tableau explicatif',
      _ => 'Tableau chiffré',
    };
    return Scaffold(
      appBar: AppBar(title: Text(titre)),
      body: switch (etat) {
        AsyncValue(:final value?) => switch (value) {
          TableauAbsent() => const EtatVide(
            icone: Icons.table_chart_outlined,
            titre: 'Aucun tableau',
            texte: 'Ce document ne porte pas de tableau chiffré.',
          ),
          TableauComparatif() => _Defilement(
            enregistre: _enregistre,
            child: _Comparatif(t: value),
          ),
          TableauExplicatif() => _Defilement(
            enregistre: _enregistre,
            child: _Explicatif(t: value),
          ),
        },
        AsyncValue(:final error?) => EtatErreur(
          message: messageErreur(error),
          onReessayer: () => ref.invalidate(tableauProvider(widget.rcId)),
        ),
        _ => const SingleChildScrollView(child: ListeSquelette(nombre: 3)),
      },
    );
  }
}

class _Defilement extends StatelessWidget {
  const _Defilement({required this.enregistre, required this.child});

  final bool enregistre;
  final Widget child;

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.fromLTRB(Espace.l, Espace.l, Espace.l, Espace.xxl + MediaQuery.paddingOf(context).bottom),
    children: [
      AnimatedSize(
        duration: const Duration(milliseconds: 250),
        child: enregistre
            ? const Bandeau(
                ton: Ton.succes,
                icone: Icons.check_circle_outline_rounded,
                titre: 'Lecture du tableau enregistrée',
              )
            : const SizedBox(width: double.infinity),
      ),
      child,
    ],
  );
}

// ─── Tableau comparatif ─────────────────────────────────────────────────────

/// Au-dessus du budget recalé = dépassement.
Ton _tonEcartBudget(double ecart) => ecart > 0 ? Ton.danger : (ecart < 0 ? Ton.succes : Ton.neutre);

class _Comparatif extends StatelessWidget {
  const _Comparatif({required this.t});

  final TableauComparatif t;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final noms = {for (final e in t.entreprises) e.id: e.nom};
    final retenue = t.entreprises.where((e) => e.retenue).firstOrNull?.id;
    final echelle = math.max(t.totaux.etudeRecale, t.entreprises.fold<double>(0, (m, e) => math.max(m, e.total)));
    final details = [
      t.codification,
      t.lot,
      t.statut == 'cloture' ? 'clôturé' : 'brouillon',
    ].whereType<String>().join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.nom, style: Typo.sousTitre.copyWith(color: p.texte)),
        const SizedBox(height: 2),
        Text(details, style: Typo.secondaire.copyWith(color: p.texteSecondaire)),
        const SizedBox(height: Espace.l),
        Section(
          titre: 'Budget',
          child: Column(
            children: [
              LigneInfo(libelle: 'Budget étude', valeur: Format.euros(t.totaux.budgetEtude)),
              LigneInfo(libelle: 'Transfert', valeur: Format.euros(t.totaux.transfert)),
              LigneInfo(
                libelle: 'Étude recalé',
                valeur: Format.euros(t.totaux.etudeRecale),
                fort: true,
                derniere: !(t.totaux.objectif > 0),
              ),
              if (t.totaux.objectif > 0)
                LigneInfo(libelle: 'Objectif', valeur: Format.euros(t.totaux.objectif), derniere: true),
            ],
          ),
        ),
        Section(
          titre: 'Offres reçues (${t.entreprises.length})',
          nu: true,
          child: Column(
            children: [
              for (final e in t.entreprises)
                Padding(
                  padding: const EdgeInsets.only(bottom: Espace.m),
                  child: Carte(
                    couleurBord: e.retenue ? p.succes : null,
                    epaisseurBord: e.retenue ? 1.6 : 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.nom,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Typo.corpsFort.copyWith(color: p.texte),
                              ),
                            ),
                            if (e.retenue)
                              const Pastille(
                                libelle: 'Retenue',
                                ton: Ton.succes,
                                petite: true,
                                icone: Icons.verified_rounded,
                              ),
                          ],
                        ),
                        const SizedBox(height: Espace.xs),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            Format.euros(e.total),
                            style: Typo.montantFort.copyWith(color: context.sombre ? p.texte : p.marine),
                          ),
                        ),
                        const SizedBox(height: Espace.s),
                        _BarreOffre(total: e.total, budget: t.totaux.etudeRecale, echelle: echelle, retenue: e.retenue),
                        const SizedBox(height: Espace.s + 2),
                        Wrap(
                          spacing: Espace.s,
                          runSpacing: Espace.xs,
                          children: [
                            Pastille(
                              libelle: '${Format.eurosSignes(e.ecartBudget, arrondi: true)} vs recalé',
                              ton: _tonEcartBudget(e.ecartBudget),
                              petite: true,
                            ),
                            if (e.prixManquants > 0)
                              Pastille(
                                libelle: Format.pluriel(e.prixManquants, 'prix manquant', 'prix manquants'),
                                ton: Ton.alerte,
                                petite: true,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (t.justification != null && t.justification!.isNotEmpty)
          Section(
            titre: 'Justification',
            padding: const EdgeInsets.all(Espace.l),
            child: Text(t.justification!, style: Typo.corps.copyWith(color: p.texte)),
          ),
        Section(
          titre: 'Détail des articles',
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, art) in t.articles.indexed)
                art.titre
                    ? Container(
                        decoration: BoxDecoration(
                          color: p.marine,
                          borderRadius: i == 0 ? const BorderRadius.vertical(top: Radius.circular(Rayon.l - 1)) : null,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: Espace.l, vertical: Espace.s + 1),
                        child: Text(
                          art.designation,
                          style: Typo.sousTitre.copyWith(fontSize: 15.5, color: Colors.white),
                        ),
                      )
                    : _Article(art: art, noms: noms, retenue: retenue, derniere: i == t.articles.length - 1),
            ],
          ),
        ),
      ],
    );
  }
}

/// Total d'une offre face au budget recalé (repère vertical).
class _BarreOffre extends StatelessWidget {
  const _BarreOffre({required this.total, required this.budget, required this.echelle, required this.retenue});

  final double total;
  final double budget;
  final double echelle;
  final bool retenue;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    if (echelle <= 0) return const SizedBox.shrink();
    final depasse = total > budget;
    return Semantics(
      label: depasse ? 'Au-dessus du budget recalé' : 'Dans le budget recalé',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, c) {
          final repere = c.maxWidth * (budget / echelle).clamp(0.0, 1.0);
          return SizedBox(
            height: 12,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  top: 3,
                  bottom: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: p.chevronVide, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 3,
                  bottom: 3,
                  width: c.maxWidth * (total / echelle).clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: depasse ? p.danger : (retenue ? p.succes : p.chevronMoyen),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Positioned(
                  left: repere - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: p.texte.withValues(alpha: 0.6)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Article extends StatelessWidget {
  const _Article({required this.art, required this.noms, required this.retenue, required this.derniere});

  final ArticleComparatif art;
  final Map<int, String> noms;
  final int? retenue;
  final bool derniere;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final details = [
      '${Format.nombre(art.quantite)} ${art.unite ?? ''}'.trim(),
      'budget ${Format.euros(art.ptBudget)}',
      if (art.exclu) 'exclu',
      if (art.transfere) 'transféré',
    ].join(', ');
    return Opacity(
      opacity: art.exclu ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Espace.l, vertical: Espace.m),
        decoration: BoxDecoration(
          border: derniere ? null : Border(bottom: BorderSide(color: p.bordure)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              art.designation,
              style: Typo.corps.copyWith(color: p.texte, decoration: art.exclu ? TextDecoration.lineThrough : null),
            ),
            Text(details, style: Typo.secondaire.copyWith(color: p.texteSecondaire)),
            if (art.observation != null)
              Text(
                art.observation!,
                style: Typo.secondaire.copyWith(color: p.texteSecondaire, fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: Espace.s),
            LayoutBuilder(
              builder: (context, c) {
                final largeur = (c.maxWidth - Espace.s) / 2;
                // Offre la moins chère de la ligne (au moins deux prix pour comparer).
                final chiffres = art.prix.map((x) => x.total).whereType<double>().toList();
                final moinsCher = chiffres.length > 1 ? chiffres.reduce((a, b) => a < b ? a : b) : null;
                return Wrap(
                  spacing: Espace.s,
                  runSpacing: Espace.s,
                  children: [
                    for (final prix in art.prix)
                      Container(
                        width: largeur,
                        padding: const EdgeInsets.all(Espace.s),
                        decoration: BoxDecoration(
                          color: prix.entrepriseId == retenue ? p.succesFond : p.fond,
                          borderRadius: BorderRadius.circular(Rayon.s),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              noms[prix.entrepriseId] ?? '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Typo.petit.copyWith(color: p.texteSecondaire, fontWeight: FontWeight.w600),
                            ),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    prix.total == null ? 'non chiffré' : Format.euros(prix.total),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Typo.montant.copyWith(
                                      fontSize: 16,
                                      color: prix.total == null ? p.alerte : p.texte,
                                    ),
                                  ),
                                ),
                                if (moinsCher != null && prix.total == moinsCher)
                                  Tooltip(
                                    message: 'Prix le plus bas de la ligne',
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 3),
                                      child: Icon(Icons.south_rounded, size: 15, color: p.succes),
                                    ),
                                  ),
                              ],
                            ),
                            if (prix.prixUnitaire != null)
                              Text(
                                'PU ${Format.euros(prix.prixUnitaire)}${prix.quantite != null ? ' × ${Format.nombre(prix.quantite)}' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Typo.petit.copyWith(fontSize: 11.5, color: p.texteTertiaire),
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tableau explicatif (avenant) ───────────────────────────────────────────

class _Explicatif extends StatelessWidget {
  const _Explicatif({required this.t});

  final TableauExplicatif t;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final tot = t.totaux;
    Color? ton(double v) => v < 0 ? p.danger : (v > 0 ? p.succes : null);
    final details = [
      t.codification,
      t.cloture ? 'clôturé' : 'brouillon',
      'FG ${Format.pourcentage(t.fgTaux * 100)}',
    ].whereType<String>().join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(details, style: Typo.secondaire.copyWith(color: p.texteSecondaire)),
        const SizedBox(height: Espace.l),
        Section(
          titre: 'Synthèse',
          child: Column(
            children: [
              LigneInfo(libelle: "Montant de l'avenant", valeur: Format.euros(tot.montantAvenant), fort: true),
              LigneInfo(libelle: 'Budget travaux', valeur: Format.euros(tot.budgetTravaux)),
              LigneInfo(libelle: 'Marge', valeur: Format.euros(tot.marge), couleur: tot.marge < 0 ? p.danger : null),
              LigneInfo(
                libelle: 'Écart SST / objectif travaux',
                valeur: Format.euros(tot.ecartSstObjectifTravaux),
                couleur: ton(tot.ecartSstObjectifTravaux),
                derniere: true,
              ),
            ],
          ),
        ),
        Section(
          titre: 'Totaux par colonne',
          child: Column(
            children: [
              LigneInfo(libelle: 'Total montant client', valeur: Format.euros(tot.totalMontantClient)),
              LigneInfo(libelle: 'Total montant ST (TS client)', valeur: Format.euros(tot.totalMontantStClient)),
              LigneInfo(libelle: 'Total FG', valeur: Format.euros(tot.totalFg)),
              LigneInfo(libelle: 'Total budget travaux', valeur: Format.euros(tot.totalBudgetTravaux)),
              LigneInfo(
                libelle: 'Total montant ST (hors TS)',
                valeur: Format.euros(tot.totalMontantStNonClient),
                derniere: true,
              ),
            ],
          ),
        ),
        Section(
          titre: 'Lignes (${t.lignes.length})',
          nu: true,
          child: Column(
            children: [
              for (final l in t.lignes)
                Padding(
                  padding: EdgeInsets.only(bottom: Espace.s, left: l.isSousLigne ? Espace.l : 0),
                  child: Carte(
                    padding: const EdgeInsets.fromLTRB(Espace.l, Espace.m, Espace.l, Espace.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (l.isSousLigne) ...[
                              Icon(Icons.subdirectory_arrow_right_rounded, size: 16, color: p.texteTertiaire),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                l.designation.isEmpty ? '—' : l.designation,
                                style: Typo.corpsFort.copyWith(color: p.texte),
                              ),
                            ),
                          ],
                        ),
                        if (l.osNumero != null || l.numeroDevisClient != null)
                          Text(
                            [
                              if (l.osNumero != null) 'OS ${l.osNumero}',
                              if (l.numeroDevisClient != null) 'devis ${l.numeroDevisClient}',
                            ].join(', '),
                            style: Typo.secondaire.copyWith(color: p.texteSecondaire),
                          ),
                        if (l.montantClient != null || l.montantStClient != null) ...[
                          LigneInfo(libelle: 'Montant client', valeur: Format.euros(l.montantClient)),
                          LigneInfo(libelle: 'Montant ST', valeur: Format.euros(l.montantStClient)),
                          LigneInfo(libelle: 'FG', valeur: Format.euros(l.fg)),
                          LigneInfo(libelle: 'Marge chantier', valeur: Format.euros(l.margeClient), derniere: true),
                        ],
                        if (l.montantBudgetTravaux != null || l.montantStNonClient != null) ...[
                          LigneInfo(libelle: 'Provenance du budget', valeur: l.provenanceBudget),
                          LigneInfo(libelle: 'Budget travaux', valeur: Format.euros(l.montantBudgetTravaux)),
                          LigneInfo(libelle: 'Montant ST (hors TS)', valeur: Format.euros(l.montantStNonClient)),
                          LigneInfo(libelle: 'Marge chantier', valeur: Format.euros(l.margeNonClient), derniere: true),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (t.commentaires != null && t.commentaires!.isNotEmpty)
          Section(
            titre: 'Commentaires',
            padding: const EdgeInsets.all(Espace.l),
            child: Text(t.commentaires!, style: Typo.corps.copyWith(color: p.texte)),
          ),
      ],
    );
  }
}
