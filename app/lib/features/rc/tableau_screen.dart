import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
      appBar: AppBar(title: Text(titre), flexibleSpace: const DegradeEnTete()),
      body: switch (etat) {
        AsyncValue(:final value?) => switch (value) {
          TableauAbsent() => const EtatVide(
            icone: LucideIcons.table,
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
                icone: LucideIcons.checkCircle,
                titre: 'Lecture du tableau enregistrée',
              )
            : const SizedBox(width: double.infinity),
      ),
      child,
    ],
  );
}

// ─── Couleurs des tableaux du web ───────────────────────────────────────────

/// Couleurs de `TableauComparatif.tsx` / `TableauExplicatif.tsx`. Le web n'a pas
/// de tableaux sombres : en mode sombre, les fonds pâles passent aux familles
/// Tailwind sombres équivalentes ; les bandeaux d'en-tête gardent leurs couleurs.
class _Couleurs {
  factory _Couleurs.de(BuildContext context) {
    final p = context.dg;
    if (!context.sombre) {
      return _Couleurs._(
        retenuFond: Marque.retenuFond,
        retenu: Marque.retenu,
        retenuTexte: Marque.retenuTexte,
        retenuBord: Marque.retenuBord,
        sectionFond: Marque.tableauSection,
        sectionTexte: Marque.tableauBudget,
        sousFondBudget: Marque.tableauBudgetSousFond,
        sousTexteBudget: Marque.tableauBudgetSousTexte,
        sousFondObjectif: Marque.tableauObjectifSousFond,
        sousTexteObjectif: Marque.tableauObjectif,
        cellule: Marque.tableauCellule,
        pied: Marque.tableauPied,
        piedTexte: Marque.marine,
        ecartNegatif: Marque.ecartNegatif,
        ecartNeutre: Marque.ecartNeutre,
        barre: Marque.tableauBudget,
      );
    }
    return _Couleurs._(
      retenuFond: p.vert.fondDoux,
      retenu: p.vert.texte,
      retenuTexte: p.vert.vif,
      retenuBord: p.vert.bord,
      sectionFond: p.bleu.fondDoux,
      sectionTexte: p.bleu.texte,
      sousFondBudget: p.bleu.fondDoux,
      sousTexteBudget: p.bleu.texte,
      sousFondObjectif: p.indigo.fondDoux,
      sousTexteObjectif: p.indigo.texte,
      cellule: p.surfaceRelief,
      pied: p.bleu.fond,
      piedTexte: p.texte,
      ecartNegatif: p.rouge.vif,
      ecartNeutre: p.texteSecondaire,
      barre: p.bleu.vif,
    );
  }

  const _Couleurs._({
    required this.retenuFond,
    required this.retenu,
    required this.retenuTexte,
    required this.retenuBord,
    required this.sectionFond,
    required this.sectionTexte,
    required this.sousFondBudget,
    required this.sousTexteBudget,
    required this.sousFondObjectif,
    required this.sousTexteObjectif,
    required this.cellule,
    required this.pied,
    required this.piedTexte,
    required this.ecartNegatif,
    required this.ecartNeutre,
    required this.barre,
  });

  final Color retenuFond;
  final Color retenu;
  final Color retenuTexte;
  final Color retenuBord;
  final Color sectionFond;
  final Color sectionTexte;
  final Color sousFondBudget;
  final Color sousTexteBudget;
  final Color sousFondObjectif;
  final Color sousTexteObjectif;
  final Color cellule;
  final Color pied;
  final Color piedTexte;
  final Color ecartNegatif;
  final Color ecartNeutre;
  final Color barre;
}

/// Carte d'un tableau du web : `bg-white border border-gray-200 rounded-lg shadow-sm`.
class _Tableau extends StatelessWidget {
  const _Tableau({required this.children, this.bord});

  final List<Widget> children;
  final Color? bord;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: bord ?? p.bordure, width: bord == null ? 1 : 1.5),
        borderRadius: BorderRadius.circular(Rayon.m),
        boxShadow: context.sombre ? null : OmbreWeb.sm,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

/// Bandeau d'en-tête de colonne : fond plein, `text-[11px] font-bold uppercase tracking-wide text-white`.
class _Bande extends StatelessWidget {
  const _Bande(this.texte, {required this.couleur});

  final String texte;
  final Color couleur;

  @override
  Widget build(BuildContext context) => Container(
    color: couleur,
    padding: const EdgeInsets.symmetric(horizontal: Espace.m, vertical: Espace.s),
    child: Text(
      texte.toUpperCase(),
      style: Typo.surTitre.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
    ),
  );
}

/// Ligne libellé / montant d'un tableau (`tabular-nums`, aligné à droite).
class _Cellule extends StatelessWidget {
  const _Cellule({
    required this.libelle,
    required this.valeur,
    this.fond,
    this.couleurLibelle,
    this.couleurValeur,
    this.fort = false,
    this.bordHaut,
    this.derniere = false,
  });

  final String libelle;
  final String? valeur;
  final Color? fond;
  final Color? couleurLibelle;
  final Color? couleurValeur;
  final bool fort;
  final Color? bordHaut;
  final bool derniere;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final v = valeur == null || valeur!.isEmpty ? '—' : valeur!;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Espace.m, vertical: Espace.s + 1),
        decoration: BoxDecoration(
          color: fond,
          border: Border(
            top: bordHaut == null ? BorderSide.none : BorderSide(color: bordHaut!, width: 2),
            bottom: derniere ? BorderSide.none : BorderSide(color: p.bordure),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 11,
              child: Text(
                libelle,
                style: Typo.secondaire.copyWith(
                  color: couleurLibelle ?? p.texteSecondaire,
                  fontWeight: fort ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: Espace.m),
            Expanded(
              flex: 10,
              child: SelectableText(
                v,
                textAlign: TextAlign.right,
                style: Typo.montant.copyWith(
                  fontSize: 14.5,
                  fontWeight: fort ? FontWeight.w700 : FontWeight.w600,
                  color: couleurValeur ?? p.texte,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tableau comparatif ─────────────────────────────────────────────────────

class _Comparatif extends StatelessWidget {
  const _Comparatif({required this.t});

  final TableauComparatif t;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final c = _Couleurs.de(context);
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
        Text(t.nom, style: Typo.sousTitre.copyWith(color: p.titre)),
        const SizedBox(height: 2),
        Text(details, style: Typo.secondaire.copyWith(color: p.texteSecondaire)),
        const SizedBox(height: Espace.l),
        Section(
          titre: 'Budget',
          icone: LucideIcons.table,
          nu: true,
          child: _Tableau(
            children: [
              const _Bande('Budget étude', couleur: Marque.tableauBudget),
              _Cellule(
                libelle: 'Budget étude',
                valeur: Format.euros(t.totaux.budgetEtude),
                fond: c.sousFondBudget,
                couleurLibelle: c.sousTexteBudget,
              ),
              _Cellule(
                libelle: 'Transfert',
                valeur: Format.euros(t.totaux.transfert),
                fond: c.sousFondBudget,
                couleurLibelle: c.sousTexteBudget,
              ),
              // « Étude Recalé » : sous-en-tête gris du web (`#6b7280` sur `#f3f4f6`).
              _Cellule(
                libelle: 'Étude recalé',
                valeur: Format.euros(t.totaux.etudeRecale),
                fond: p.gris.fond,
                couleurLibelle: context.sombre ? p.texteSecondaire : Marque.tableauLot,
                couleurValeur: p.titre,
                fort: true,
                derniere: !(t.totaux.objectif > 0),
              ),
              if (t.totaux.objectif > 0) ...[
                const _Bande('Objectif', couleur: Marque.tableauObjectif),
                _Cellule(
                  libelle: 'Objectif',
                  valeur: Format.euros(t.totaux.objectif),
                  fond: c.sousFondObjectif,
                  couleurLibelle: c.sousTexteObjectif,
                  couleurValeur: c.sousTexteObjectif,
                  fort: true,
                  derniere: true,
                ),
              ],
            ],
          ),
        ),
        Section(
          titre: 'Offres reçues (${t.entreprises.length})',
          icone: LucideIcons.building2,
          nu: true,
          child: Column(
            children: [
              for (final e in t.entreprises)
                Padding(
                  padding: const EdgeInsets.only(bottom: Espace.m),
                  child: _Offre(e: e, budget: t.totaux.etudeRecale, echelle: echelle),
                ),
            ],
          ),
        ),
        if (t.justification != null && t.justification!.isNotEmpty)
          Section(
            titre: 'Justification',
            icone: LucideIcons.messageSquare,
            padding: const EdgeInsets.all(Espace.l),
            child: Text(t.justification!, style: Typo.corps.copyWith(color: p.texte)),
          ),
        Section(
          titre: 'Détail des articles',
          icone: LucideIcons.fileText,
          nu: true,
          child: _Tableau(
            children: [
              for (final (i, art) in t.articles.indexed)
                art.titre
                    // Ligne de section : fond `#EFF6FF`, liseré gauche 4 px `#0261A7`, texte gras.
                    ? Container(
                        decoration: BoxDecoration(
                          color: c.sectionFond,
                          border: Border(
                            left: const BorderSide(color: Marque.tableauBudget, width: 4),
                            bottom: BorderSide(color: p.bordure),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: Espace.m, vertical: Espace.s + 1),
                        child: Text(
                          art.designation,
                          style: Typo.libelle.copyWith(fontWeight: FontWeight.w700, color: c.sectionTexte),
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

/// Offre d'une entreprise : en-tête `bg-gray-50` (vert `#E8F5EE` si retenue),
/// pied `#0261A7` (`#517A52` si retenue) portant le total.
class _Offre extends StatelessWidget {
  const _Offre({required this.e, required this.budget, required this.echelle});

  final OffreEntreprise e;
  final double budget;
  final double echelle;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final c = _Couleurs.de(context);
    // Écart = total − recalé : au-dessus du budget, l'écart s'affiche en rouge comme sur le web.
    final couleurEcart = e.ecartBudget > 0 ? c.ecartNegatif : (e.retenue ? c.retenuTexte : c.ecartNeutre);
    return _Tableau(
      bord: e.retenue ? c.retenuBord : null,
      children: [
        Container(
          color: e.retenue ? c.retenuFond : p.gris.fondDoux,
          padding: const EdgeInsets.fromLTRB(Espace.m, Espace.s + 2, Espace.m, Espace.s + 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  e.nom,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Typo.libelle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: e.retenue ? c.retenu : p.texte,
                  ),
                ),
              ),
              if (e.retenue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Marque.retenu, borderRadius: BorderRadius.circular(Rayon.s)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.check, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('Retenue', style: Typo.sigle.copyWith(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Espace.m, Espace.m, Espace.m, Espace.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BarreOffre(total: e.total, budget: budget, echelle: echelle, retenue: e.retenue),
              const SizedBox(height: Espace.s + 2),
              Wrap(
                spacing: Espace.s,
                runSpacing: Espace.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Δ ${Format.eurosSignes(e.ecartBudget, arrondi: true)} vs recalé',
                    style: Typo.petit.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: couleurEcart),
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
        Container(
          color: e.retenue ? Marque.retenu : Marque.tableauBudget,
          padding: const EdgeInsets.symmetric(horizontal: Espace.m, vertical: Espace.s + 1),
          child: Row(
            children: [
              Text(
                'TOTAL',
                style: Typo.surTitre.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: Espace.m),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    Format.euros(e.total),
                    style: Typo.montantMoyen.copyWith(color: Colors.white),
                  ),
                ),
              ),
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
    final c = _Couleurs.de(context);
    if (echelle <= 0) return const SizedBox.shrink();
    final depasse = total > budget;
    return Semantics(
      label: depasse ? 'Au-dessus du budget recalé' : 'Dans le budget recalé',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, contraintes) {
          final repere = contraintes.maxWidth * (budget / echelle).clamp(0.0, 1.0);
          return SizedBox(
            height: 12,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  top: 3,
                  bottom: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: p.bordure, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 3,
                  bottom: 3,
                  width: contraintes.maxWidth * (total / echelle).clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: depasse ? c.ecartNegatif : (retenue ? Marque.retenu : c.barre),
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
    final c = _Couleurs.de(context);
    final details = [
      '${Format.nombre(art.quantite)} ${art.unite ?? ''}'.trim(),
      'budget ${Format.euros(art.ptBudget)}',
      if (art.exclu) 'exclu',
      if (art.transfere) 'transféré',
    ].join(', ');
    // Ligne verrouillée / exclue : `bg-gray-100 text-gray-400` sur le web.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Espace.m, vertical: Espace.m),
      decoration: BoxDecoration(
        color: art.exclu ? p.gris.fond : null,
        border: derniere ? null : Border(bottom: BorderSide(color: p.bordure)),
      ),
      child: Opacity(
        opacity: art.exclu ? 0.6 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              art.designation,
              style: Typo.secondaire.copyWith(
                color: p.texte,
                fontWeight: FontWeight.w500,
                decoration: art.exclu ? TextDecoration.lineThrough : null,
              ),
            ),
            Text(details, style: Typo.petit.copyWith(color: p.texteTertiaire, fontWeight: FontWeight.w400)),
            if (art.observation != null)
              // Commentaires de ligne : `text-[10px] text-red-600` sur le web.
              Text(
                art.observation!,
                style: Typo.petit.copyWith(color: p.rouge.vif, fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: Espace.s),
            LayoutBuilder(
              builder: (context, contraintes) {
                final largeur = (contraintes.maxWidth - Espace.s) / 2;
                // Offre la moins chère de la ligne (au moins deux prix pour comparer).
                final chiffres = art.prix.map((x) => x.total).whereType<double>().toList();
                final moinsCher = chiffres.length > 1 ? chiffres.reduce((a, b) => a < b ? a : b) : null;
                return Wrap(
                  spacing: Espace.s,
                  runSpacing: Espace.s,
                  children: [
                    for (final prix in art.prix)
                      Builder(
                        builder: (context) {
                          final estRetenue = prix.entrepriseId == retenue;
                          return Container(
                            width: largeur,
                            padding: const EdgeInsets.all(Espace.s),
                            decoration: BoxDecoration(
                              color: estRetenue ? c.retenuFond : p.gris.fondDoux,
                              border: Border.all(color: estRetenue ? c.retenuBord : p.bordure),
                              borderRadius: BorderRadius.circular(Rayon.s),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  noms[prix.entrepriseId] ?? '—',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Typo.petit.copyWith(
                                    fontSize: 11.5,
                                    color: estRetenue ? c.retenu : p.texteSecondaire,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        prix.total == null ? 'non chiffré' : Format.euros(prix.total),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Typo.montant.copyWith(
                                          fontSize: 15,
                                          color: prix.total == null
                                              ? p.orange.vif
                                              : (estRetenue ? c.retenuTexte : p.texte),
                                        ),
                                      ),
                                    ),
                                    if (moinsCher != null && prix.total == moinsCher)
                                      Tooltip(
                                        message: 'Prix le plus bas de la ligne',
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 3),
                                          child: Icon(LucideIcons.arrowDown, size: 14, color: p.vert.vif),
                                        ),
                                      ),
                                  ],
                                ),
                                if (prix.prixUnitaire != null)
                                  Text(
                                    'PU ${Format.euros(prix.prixUnitaire)}${prix.quantite != null ? ' × ${Format.nombre(prix.quantite)}' : ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Typo.petit.copyWith(fontSize: 11, color: p.texteTertiaire),
                                  ),
                              ],
                            ),
                          );
                        },
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
    final c = _Couleurs.de(context);
    final tot = t.totaux;
    Color? signe(double v) => v < 0 ? p.rouge.vif : (v > 0 ? p.vert.fonce : null);
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
          icone: LucideIcons.table,
          nu: true,
          child: _Tableau(
            children: [
              // Carte des totaux du web : « Montant de l'avenant » et « Marge » côte à côte.
              Padding(
                padding: const EdgeInsets.all(Espace.l),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _Total(
                          libelle: "Montant de l'avenant",
                          valeur: Format.euros(tot.montantAvenant),
                          couleurLibelle: p.titre,
                          couleurValeur: p.titre,
                        ),
                      ),
                      Container(width: 1, color: p.bordure, margin: const EdgeInsets.symmetric(horizontal: Espace.m)),
                      Expanded(
                        child: _Total(
                          libelle: 'Marge',
                          valeur: Format.euros(tot.marge),
                          couleurLibelle: context.sombre ? p.texteSecondaire : Tw.gray700,
                          couleurValeur: tot.marge < 0 ? p.rouge.vif : p.vert.fonce,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _Cellule(
                libelle: 'Budget travaux',
                valeur: Format.euros(tot.budgetTravaux),
                bordHaut: p.bordure,
              ),
              _Cellule(
                libelle: 'Écart SST / objectif travaux',
                valeur: Format.euros(tot.ecartSstObjectifTravaux),
                couleurValeur: signe(tot.ecartSstObjectifTravaux),
                derniere: true,
              ),
            ],
          ),
        ),
        Section(
          titre: 'Totaux par colonne',
          icone: LucideIcons.sigma,
          nu: true,
          child: _Tableau(
            children: [
              const _Bande('Totaux par colonne', couleur: Marque.tableauBudget),
              // Pied du tableau explicatif : `#e3eef8`, filet haut 2 px marine, texte marine gras.
              for (final (i, (libelle, valeur)) in [
                ('Total montant client', tot.totalMontantClient),
                ('Total montant ST (TS client)', tot.totalMontantStClient),
                ('Total FG', tot.totalFg),
                ('Total budget travaux', tot.totalBudgetTravaux),
                ('Total montant ST (hors TS)', tot.totalMontantStNonClient),
              ].indexed)
                _Cellule(
                  libelle: libelle,
                  valeur: Format.euros(valeur),
                  fond: c.pied,
                  couleurLibelle: c.piedTexte,
                  couleurValeur: valeur < 0 ? p.rouge.vif : c.piedTexte,
                  fort: true,
                  bordHaut: i == 0 ? (context.sombre ? p.bordureForte : Marque.marine) : null,
                  derniere: i == 4,
                ),
            ],
          ),
        ),
        Section(
          titre: 'Lignes (${t.lignes.length})',
          icone: LucideIcons.fileText,
          nu: true,
          child: Column(
            children: [
              for (final l in t.lignes)
                Padding(
                  padding: EdgeInsets.only(bottom: Espace.m, left: l.isSousLigne ? Espace.l : 0),
                  child: _LigneAvenant(l: l),
                ),
            ],
          ),
        ),
        if (t.commentaires != null && t.commentaires!.isNotEmpty)
          Section(
            titre: 'Commentaires',
            icone: LucideIcons.messageSquare,
            padding: const EdgeInsets.all(Espace.l),
            child: Text(t.commentaires!, style: Typo.corps.copyWith(color: p.texte)),
          ),
      ],
    );
  }
}

/// Total de la carte de synthèse : libellé `text-sm font-bold uppercase
/// tracking-wide`, valeur `text-lg font-extrabold tabular-nums`.
class _Total extends StatelessWidget {
  const _Total({required this.libelle, required this.valeur, required this.couleurLibelle, required this.couleurValeur});

  final String libelle;
  final String valeur;
  final Color couleurLibelle;
  final Color couleurValeur;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${libelle.toUpperCase()} :',
          style: Typo.surTitre.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: couleurLibelle),
        ),
        const SizedBox(height: Espace.s),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(valeur, style: Typo.montantMoyen.copyWith(color: couleurValeur)),
        ),
      ],
    ),
  );
}

/// Ligne de l'avenant : désignation, puis les deux sections du web
/// (`bg-[#172D4C]` 11 px majuscules) sur cellules `#f1f7fc`.
class _LigneAvenant extends StatelessWidget {
  const _LigneAvenant({required this.l});

  final LigneExplicatif l;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final c = _Couleurs.de(context);
    Color? negatif(double? v) => v != null && v < 0 ? p.rouge.vif : null;
    _Cellule cellule(String libelle, double? v, {bool calcul = false, bool derniere = false}) => _Cellule(
      libelle: libelle,
      valeur: Format.euros(v),
      fond: c.cellule,
      couleurValeur: negatif(v),
      fort: calcul,
      derniere: derniere,
    );
    return _Tableau(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Espace.m, Espace.m, Espace.m, Espace.s + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (l.isSousLigne) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(LucideIcons.cornerDownRight, size: 15, color: p.texteTertiaire),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      l.designation.isEmpty ? '—' : l.designation,
                      style: Typo.libelle.copyWith(color: p.texte),
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
                  style: Typo.petit.copyWith(color: p.texteSecondaire),
                ),
            ],
          ),
        ),
        if (l.montantClient != null || l.montantStClient != null) ...[
          _Bande("Travaux faisant l'objet d'un TS client", couleur: p.marine),
          cellule('Montant client', l.montantClient),
          cellule('Montant ST', l.montantStClient),
          cellule('FG', l.fg),
          cellule(
            'Marge chantier',
            l.margeClient,
            calcul: true,
            derniere: !(l.montantBudgetTravaux != null || l.montantStNonClient != null),
          ),
        ],
        if (l.montantBudgetTravaux != null || l.montantStNonClient != null) ...[
          _Bande("Travaux ne faisant pas l'objet d'un TS client", couleur: p.marine),
          _Cellule(libelle: 'Provenance du budget', valeur: l.provenanceBudget, fond: c.cellule),
          cellule('Budget travaux', l.montantBudgetTravaux),
          cellule('Montant ST (hors TS)', l.montantStNonClient),
          cellule('Marge chantier', l.margeNonClient, calcul: true, derniere: true),
        ],
      ],
    );
  }
}
