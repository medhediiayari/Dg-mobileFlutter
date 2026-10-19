import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/models.dart';
import '../../core/utils/format.dart';
import '../../core/utils/parcours.dart';
import '../../ui/telechargement.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/composants.dart';
import '../../ui/widgets/liste_pieces.dart';
import 'decision/decision_sheet.dart';

typedef OuvrirChemin = Future<void> Function(String chemin);

Color? _couleurEcart(BuildContext context, double? v) {
  if (v == null || v == 0) return null;
  return v < 0 ? context.dg.danger : context.dg.succes;
}

String? _partPaiement(double? pourcentage, double? montant) =>
    pourcentage == null && montant == null ? null : '${Format.pourcentage(pourcentage)}, ${Format.euros(montant)}';

/// Contenu de l'onglet « Fiche ».
class ContenuFiche extends StatelessWidget {
  const ContenuFiche({required this.d, required this.onOuvrir, super.key});

  final Detail d;
  final OuvrirChemin onOuvrir;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final c = d.conditions;
    final e = d.entreprise;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Bandeaux(d: d),
        _Synthese(d: d),
        _AvantDeDecider(d: d, onOuvrirTableau: () => onOuvrir('/rc/${d.id}/tableau')),
        _Documents(d: d, onOuvrir: onOuvrir),
        if (d.entreprisesConsultees.isNotEmpty)
          Section(
            titre: 'Entreprises consultées (${d.entreprisesConsultees.length})',
            child: Column(
              children: [
                for (final (i, ent) in d.entreprisesConsultees.indexed)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: i < d.entreprisesConsultees.length - 1
                          ? Border(bottom: BorderSide(color: p.bordure))
                          : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ent.nom,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: (ent.retenue ? Typo.corpsFort : Typo.corps).copyWith(color: p.texte),
                              ),
                              if (ent.retenue)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    children: [
                                      Icon(Icons.verified_rounded, size: 14, color: p.succes),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Entreprise retenue',
                                          style: Typo.petit.copyWith(color: p.succes, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (ent.observations != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    ent.observations!,
                                    style: Typo.secondaire.copyWith(color: p.texteSecondaire),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: Espace.m),
                        Text(
                          Format.euros(ent.montant),
                          style: Typo.montant.copyWith(color: ent.retenue ? p.succes : p.texte),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        Section(
          titre: 'Paiement et conditions',
          child: Column(
            children: [
              LigneInfo(
                libelle: 'Paiement direct',
                valeur: _partPaiement(d.paiement.directPourcentage, d.paiement.directMontant),
              ),
              LigneInfo(
                libelle: 'Paiement COREDIF',
                valeur: _partPaiement(d.paiement.coredifPourcentage, d.paiement.coredifMontant),
              ),
              if (d.paiement.erreur != null)
                LigneInfo(libelle: 'Contrôle', valeur: d.paiement.erreur, couleur: p.danger),
              LigneInfo(
                libelle: 'Insertion',
                valeur: c.insertion
                    ? 'Oui${c.nbreHeuresInsertion != null && c.nbreHeuresInsertion! > 0 ? ', ${Format.nombre(c.nbreHeuresInsertion)} h' : ''}'
                    : 'Non',
              ),
              LigneInfo(
                libelle: 'Prorata',
                valeur: c.prorata
                    ? 'Oui${c.pourcentageProrata != null && c.pourcentageProrata!.isNotEmpty ? ', ${c.pourcentageProrata} %' : ''}'
                    : 'Non',
              ),
              LigneInfo(libelle: 'Retenue 5 % (RG)', valeur: c.retenue5Rg ? 'Oui' : 'Non'),
              LigneInfo(libelle: 'Retenue 5 % bonne fin', valeur: c.retenue5BonneFin ? 'Oui' : 'Non'),
              LigneInfo(libelle: 'DC4 modificatif', valeur: c.dc4Modificatif ? 'Oui' : 'Non', derniere: true),
            ],
          ),
        ),
        Section(
          titre: 'Identification',
          child: Column(
            children: [
              LigneInfo(libelle: "Maître d'ouvrage", valeur: d.projet.maitreOuvrage),
              LigneInfo(libelle: "Corps d'état", valeur: d.identification.corpsEtat),
              LigneInfo(libelle: 'Prestation', valeur: d.identification.prestation),
              LigneInfo(libelle: 'N° de lot', valeur: d.identification.numeroLot),
              LigneInfo(libelle: 'Rédacteur', valeur: d.identification.redacteur),
              LigneInfo(libelle: 'Début des travaux', valeur: d.identification.dateDebut),
              LigneInfo(
                libelle: 'Fin des travaux',
                valeur: d.identification.dateFin == null ? null : Format.dateIso(d.identification.dateFin),
              ),
              LigneInfo(libelle: 'Créé le', valeur: Format.dateHeure(d.identification.creeLe)),
              LigneInfo(libelle: 'Mis à jour le', valeur: Format.dateHeure(d.identification.majLe), derniere: true),
            ],
          ),
        ),
        if (e.aUnContact)
          Section(
            titre: 'Contact entreprise',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Espace.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (e.chargeAffaire != null && e.chargeAffaire!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: Espace.xs, bottom: Espace.xs),
                      child: Text(e.chargeAffaire!, style: Typo.corpsFort.copyWith(color: p.texte)),
                    ),
                  if (e.telephone != null && e.telephone!.isNotEmpty)
                    _Contact(
                      icone: Icons.call_outlined,
                      valeur: e.telephone!,
                      uri: Uri(scheme: 'tel', path: e.telephone!.replaceAll(RegExp(r'\s'), '')),
                    ),
                  if (e.email != null && e.email!.isNotEmpty)
                    _Contact(
                      icone: Icons.mail_outline_rounded,
                      valeur: e.email!,
                      uri: Uri(scheme: 'mailto', path: e.email!),
                    ),
                  if (e.sousTraitantRang2 != null && e.sousTraitantRang2!.isNotEmpty)
                    LigneInfo(libelle: 'Sous-traitant de 2e rang', valeur: e.sousTraitantRang2, derniere: true),
                ],
              ),
            ),
          ),
        if (d.commentaire != null && d.commentaire!.isNotEmpty)
          Section(
            titre: 'Commentaire',
            padding: const EdgeInsets.all(Espace.l),
            child: SelectableText(d.commentaire!, style: Typo.corps.copyWith(color: p.texte)),
          ),
        if (d.signatures.isNotEmpty)
          Section(
            titre: 'Signatures apposées',
            child: Column(
              children: [
                for (final (i, s) in d.signatures.indexed)
                  LigneInfo(
                    libelle: s.type.isEmpty ? s.par : '${s.par} (${s.type})',
                    valeur: Format.dateHeure(s.le),
                    derniere: i == d.signatures.length - 1,
                  ),
              ],
            ),
          ),
        if (d.rcParent != null)
          Section(
            titre: "RC d'origine",
            child: _Lien(libelle: d.rcParent!.reference, onTap: () => context.push('/rc/${d.rcParent!.id}')),
          ),
        if (d.avenants.isNotEmpty)
          Section(
            titre: 'Avenants (${d.avenants.length})',
            child: Column(
              children: [
                for (final (i, av) in d.avenants.indexed)
                  _Lien(
                    libelle: av.reference,
                    detail: positionParcours(av.statut).phrase,
                    couleurDetail: positionParcours(av.statut).mode == ModeParcours.termine
                        ? p.succes
                        : p.texteSecondaire,
                    separe: i < d.avenants.length - 1,
                    onTap: () => context.push('/rc/${av.id}'),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Bandeaux : demande d'information, motif de renvoi, message reçu ───────

class _Bandeaux extends StatelessWidget {
  const _Bandeaux({required this.d});

  final Detail d;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final info = d.demandeInfo;
    final rejet = d.rejet;
    final entrant = d.messageEntrant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (info != null && info.reponse == null)
          Bandeau(
            ton: Ton.info,
            icone: Icons.forum_outlined,
            titre: info.pourMoi
                ? '${info.par ?? 'On'} vous demande une information'
                : 'Information demandée à ${info.vers ?? '—'}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (info.message != null) Text(info.message!, style: Typo.corps.copyWith(color: p.texte)),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(Format.dateHeure(info.le), style: Typo.petit.copyWith(color: p.texteSecondaire)),
                ),
                ListePieces(rcId: d.id, pieces: info.pieces),
              ],
            ),
          ),
        if (rejet != null)
          Bandeau(
            ton: Ton.danger,
            icone: Icons.undo_rounded,
            titre: 'Motif du renvoi${rejet.auteur != null ? ' (${rejet.auteur})' : ''}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rejet.motif != null) Text(rejet.motif!, style: Typo.corps.copyWith(color: p.texte)),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    [rejet.par, Format.dateHeure(rejet.le)].whereType<String>().join(', ') +
                        (rejet.vers != null ? ', renvoyé à ${rejet.vers}' : ''),
                    style: Typo.petit.copyWith(color: p.texteSecondaire),
                  ),
                ),
                ListePieces(rcId: d.id, pieces: rejet.pieces),
              ],
            ),
          )
        else if (entrant != null && ((entrant.message?.isNotEmpty ?? false) || entrant.pieces.isNotEmpty))
          Bandeau(
            ton: Ton.succes,
            icone: Icons.chat_bubble_outline_rounded,
            titre: 'Message de ${entrant.par ?? "l'étape précédente"}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entrant.message != null && entrant.message!.isNotEmpty)
                  Text(entrant.message!, style: Typo.corps.copyWith(color: p.texte)),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(Format.dateHeure(entrant.le), style: Typo.petit.copyWith(color: p.texteSecondaire)),
                ),
                ListePieces(rcId: d.id, pieces: entrant.pieces),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Synthèse : les chiffres qui décident ───────────────────────────────────

class _Tuile {
  const _Tuile(this.libelle, this.valeur, [this.couleur]);

  final String libelle;
  final String valeur;
  final Color? couleur;
}

class _Synthese extends StatefulWidget {
  const _Synthese({required this.d});

  final Detail d;

  @override
  State<_Synthese> createState() => _SyntheseState();
}

class _SyntheseState extends State<_Synthese> {
  bool _detail = false;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final d = widget.d;
    final m = d.montants;
    final av = m.avenant;
    final tuiles = d.estAvenant
        ? [
            _Tuile('Montant de l’avenant HT', Format.euros(m.montantRetenu)),
            if (av != null) ...[
              _Tuile('Marge', Format.eurosSignes(av.marge), _couleurEcart(context, av.marge)),
              _Tuile('Budget travaux', Format.euros(av.budgetTravaux)),
              _Tuile('Écart SST / objectif', Format.eurosSignes(av.ecart), _couleurEcart(context, av.ecart)),
            ],
          ]
        : [
            _Tuile('Montant retenu', Format.euros(m.montantRetenu)),
            _Tuile('Écart SST / étude', Format.eurosSignes(m.ecartsSstEtude), _couleurEcart(context, m.ecartsSstEtude)),
            _Tuile('Budget étude recalé', Format.euros(m.budgetEtudeRecale)),
            _Tuile('Objectif travaux recalé', Format.euros(m.objectifTravauxRecale)),
          ];

    final montant = m.montantRetenu;
    final budget = m.budgetEtudeRecale;

    return Section(
      titre: 'Synthèse',
      droite: m.montantDepuisTableauExplicatif
          ? Text('selon le tableau explicatif', style: Typo.petit.copyWith(color: p.texteTertiaire))
          : null,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Première tuile pleine largeur : le montant engagé.
          Padding(
            padding: const EdgeInsets.fromLTRB(Espace.l, Espace.l, Espace.l, Espace.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tuiles.first.libelle, style: Typo.petit.copyWith(color: p.texteSecondaire)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(tuiles.first.valeur, style: Typo.montantFort.copyWith(color: p.texte)),
                ),
                // Engagé face au budget étude : pertinent pour un RC. Pour un avenant, le
                // montant client dépasse normalement le budget travaux (c'est la marge).
                if (!d.estAvenant && montant != null && budget != null && budget > 0) ...[
                  const SizedBox(height: Espace.m),
                  _Jauge(montant: montant, budget: budget, libelleBudget: 'budget étude recalé'),
                ],
              ],
            ),
          ),
          if (tuiles.length > 1)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: p.bordure)),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, t) in tuiles.skip(1).indexed) ...[
                      if (i > 0) VerticalDivider(width: 1, color: p.bordure),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(Espace.m, Espace.m, Espace.s, Espace.m),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.libelle, maxLines: 2, style: Typo.petit.copyWith(color: p.texteSecondaire)),
                              const Spacer(),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  t.valeur,
                                  style: Typo.montant.copyWith(fontSize: 17.5, color: t.couleur ?? p.texte),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (!d.estAvenant) ...[
            InkWell(
              onTap: () => setState(() => _detail = !_detail),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: p.bordure)),
                ),
                alignment: Alignment.center,
                child: Semantics(
                  expanded: _detail,
                  button: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _detail ? 'Masquer le détail' : 'Détail des montants',
                        style: Typo.libelle.copyWith(color: p.action),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _detail ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.expand_more_rounded, size: 20, color: p.action),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !_detail
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Espace.l),
                      child: Column(
                        children: [
                          LigneInfo(libelle: 'Budget prestation', valeur: Format.euros(m.budgetPrestation)),
                          LigneInfo(libelle: 'Budget étude', valeur: Format.euros(m.budgetEtude)),
                          LigneInfo(libelle: 'Transfert étude', valeur: Format.euros(m.transfertEtude)),
                          LigneInfo(libelle: 'Budget étude recalé', valeur: Format.euros(m.budgetEtudeRecale)),
                          LigneInfo(libelle: 'Objectif travaux', valeur: Format.euros(m.objectifTravaux)),
                          LigneInfo(libelle: 'Transfert travaux', valeur: Format.euros(m.transfertTravaux)),
                          LigneInfo(libelle: 'Objectif travaux recalé', valeur: Format.euros(m.objectifTravauxRecale)),
                          LigneInfo(
                            libelle: 'Écart SST / étude',
                            valeur: Format.eurosSignes(m.ecartsSstEtude),
                            couleur: _couleurEcart(context, m.ecartsSstEtude),
                          ),
                          LigneInfo(
                            libelle: 'Écart SST / travaux',
                            valeur: Format.eurosSignes(m.ecartsSstTravaux),
                            couleur: _couleurEcart(context, m.ecartsSstTravaux),
                            derniere: true,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Montant engagé rapporté au budget : barre pleine, repère à 100 %.
class _Jauge extends StatelessWidget {
  const _Jauge({required this.montant, required this.budget, required this.libelleBudget});

  final double montant;
  final double budget;
  final String libelleBudget;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final ratio = montant / budget;
    final depasse = ratio > 1;
    final couleur = depasse ? p.danger : p.succes;
    final pourcent = (ratio * 100).round();
    return Semantics(
      label: '$pourcent % du $libelleBudget',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final echelle = depasse ? ratio : 1.0;
              final largeurBudget = c.maxWidth / echelle;
              return SizedBox(
                height: 10,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: p.chevronVide, borderRadius: BorderRadius.circular(5)),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: (ratio / echelle).clamp(0.0, 1.0)),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Positioned.fill(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: v,
                            heightFactor: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(5)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: largeurBudget - 1,
                      top: -3,
                      bottom: -3,
                      child: Container(width: 2, color: p.texte.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            depasse
                ? '$pourcent % du $libelleBudget : dépassement de ${Format.euros(montant - budget, arrondi: true)}'
                : '$pourcent % du $libelleBudget',
            style: Typo.petit.copyWith(color: depasse ? p.danger : p.texteSecondaire),
          ),
        ],
      ),
    );
  }
}

// ─── Avant de décider : la garde rendue lisible ─────────────────────────────

class _Condition {
  const _Condition({required this.ok, required this.libelle, this.aide, this.action});

  final bool ok;
  final String libelle;
  final String? aide;
  final (String, VoidCallback)? action;
}

class _AvantDeDecider extends StatelessWidget {
  const _AvantDeDecider({required this.d, required this.onOuvrirTableau});

  final Detail d;
  final VoidCallback onOuvrirTableau;

  @override
  Widget build(BuildContext context) {
    final a = d.actions;
    if (!a.decideur) return const SizedBox.shrink();
    final p = context.dg;
    final g = d.consultation;
    final approbation = a.peutApprouver || a.peutConvertirBc;
    final conditions = [
      _Condition(
        ok: g.documentOk,
        libelle: g.perimee ? 'Relire la fiche : elle a changé depuis votre lecture' : 'Fiche lue',
      ),
      if (g.tableauRequis)
        _Condition(
          ok: g.tableauOk,
          libelle: '${d.nomTableau} consulté',
          action: g.tableauOk ? null : ('Ouvrir', onOuvrirTableau),
        ),
      if (approbation) ...[
        _Condition(ok: a.paiementBloquant == null, libelle: 'Paiement cohérent', aide: a.paiementBloquant),
        _Condition(
          ok: !a.signatureManquante,
          libelle: 'Signature enregistrée au profil',
          aide: a.signatureManquante ? 'À ajouter dans votre profil DG Flow (web).' : null,
        ),
      ],
    ];
    final faites = conditions.where((c) => c.ok).length;

    return Section(
      titre: 'Avant de décider',
      droite: Text(
        '$faites / ${conditions.length}',
        style: Typo.montant.copyWith(fontSize: 15, color: faites == conditions.length ? p.succes : p.alerte),
      ),
      child: Column(
        children: [
          for (final (i, c) in conditions.indexed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: Espace.m),
              decoration: BoxDecoration(
                border: i < conditions.length - 1 ? Border(bottom: BorderSide(color: p.bordure)) : null,
              ),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (e, a) => ScaleTransition(scale: a, child: e),
                    child: Icon(
                      c.ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      key: ValueKey(c.ok),
                      size: 23,
                      color: c.ok ? p.succes : p.alerte,
                    ),
                  ),
                  const SizedBox(width: Espace.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.libelle,
                          style: Typo.corps.copyWith(
                            color: p.texte,
                            fontWeight: c.ok ? FontWeight.w400 : FontWeight.w600,
                          ),
                        ),
                        if (c.aide != null) Text(c.aide!, style: Typo.secondaire.copyWith(color: p.texteSecondaire)),
                      ],
                    ),
                  ),
                  if (c.action != null) ...[
                    const SizedBox(width: Espace.s),
                    LienPilule(libelle: c.action!.$1, onTap: c.action!.$2),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Documents : tableau, dossier « Fichiers », Excel ───────────────────────

class _Documents extends ConsumerStatefulWidget {
  const _Documents({required this.d, required this.onOuvrir});

  final Detail d;
  final OuvrirChemin onOuvrir;

  @override
  ConsumerState<_Documents> createState() => _DocumentsState();
}

class _DocumentsState extends ConsumerState<_Documents> {
  String? _enCours;
  double? _progression;

  Future<void> _telecharger(String quoi) async {
    final d = widget.d;
    setState(() {
      _enCours = quoi;
      _progression = null;
    });
    await telechargerEtOuvrir(
      context,
      ref,
      chemin: '/rc/${d.id}/export/$quoi',
      nom: quoi == 'document' ? '${d.reference}.xlsx' : '${d.nomTableau} ${d.reference}.xlsx',
      type: typeExcel,
      progression: (v) {
        if (mounted) setState(() => _progression = v);
      },
    );
    if (mounted) setState(() => _enCours = null);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final d = widget.d;
    Widget roue() =>
        SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.4, value: _progression));
    final lignes = <(IconData, String, String?, Widget?, VoidCallback)>[
      if (d.tableau != null)
        (
          Icons.table_chart_outlined,
          d.nomTableau,
          d.consultation.tableauOk ? 'Consulté' : 'Pas encore consulté',
          d.consultation.tableauOk ? Icon(Icons.check_circle_rounded, size: 21, color: p.succes) : null,
          () => widget.onOuvrir('/rc/${d.id}/tableau'),
        ),
      (
        Icons.folder_open_outlined,
        'Fichiers du dossier (${d.nombreFichiers})',
        null,
        null,
        () => widget.onOuvrir('/rc/${d.id}/fichiers'),
      ),
      (
        Icons.download_outlined,
        '${d.estAvenant ? "L'avenant" : 'Le RC'} en Excel',
        d.estAvenant ? 'Modèle FIN 1-2' : 'Modèle FIN 1-1',
        _enCours == 'document' ? roue() : null,
        () => _telecharger('document'),
      ),
      if (d.tableau != null)
        (
          Icons.download_outlined,
          '${d.nomTableau} en Excel',
          null,
          _enCours == 'tableau' ? roue() : null,
          () => _telecharger('tableau'),
        ),
    ];
    return Section(
      titre: 'Documents',
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, (icone, libelle, detail, droite, onTap)) in lignes.indexed)
            InkWell(
              onTap: _enCours == null ? onTap : null,
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(horizontal: Espace.l, vertical: Espace.m),
                decoration: BoxDecoration(
                  border: i < lignes.length - 1 ? Border(bottom: BorderSide(color: p.bordure)) : null,
                ),
                child: Row(
                  children: [
                    Icon(icone, size: 22, color: p.action),
                    const SizedBox(width: Espace.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(libelle, style: Typo.corpsFort.copyWith(color: p.action)),
                          if (detail != null) Text(detail, style: Typo.secondaire.copyWith(color: p.texteSecondaire)),
                        ],
                      ),
                    ),
                    droite ?? Icon(Icons.chevron_right_rounded, color: p.texteTertiaire),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact({required this.icone, required this.valeur, required this.uri});

  final IconData icone;
  final String valeur;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    return InkWell(
      onTap: () => launchUrl(uri),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Icon(icone, size: 20, color: p.action),
            const SizedBox(width: Espace.s + 2),
            Expanded(
              child: Text(valeur, style: Typo.corps.copyWith(color: p.action)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Lien extends StatelessWidget {
  const _Lien({required this.libelle, required this.onTap, this.detail, this.couleurDetail, this.separe = false});

  final String libelle;
  final String? detail;
  final Color? couleurDetail;
  final bool separe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: separe ? Border(bottom: BorderSide(color: p.bordure)) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(libelle, style: Typo.corpsFort.copyWith(color: p.action)),
                  if (detail != null)
                    Text(detail!, style: Typo.petit.copyWith(color: couleurDetail ?? p.texteSecondaire)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.texteTertiaire),
          ],
        ),
      ),
    );
  }
}

// ─── Barre de décision (collée en bas) ──────────────────────────────────────

class BarreDecision extends StatelessWidget {
  const BarreDecision({required this.d, required this.onDecider, required this.onOuvrirTableau, super.key});

  final Detail d;
  final ValueChanged<ModeDecision> onDecider;
  final VoidCallback onOuvrirTableau;

  @override
  Widget build(BuildContext context) {
    final a = d.actions;
    final decide = a.peutApprouver || a.peutRejeter || a.peutConvertirBc || a.peutAnnulerBc;
    if (!decide && !a.peutRepondreInfo && !a.peutDemanderInfo) return const SizedBox.shrink();
    final p = context.dg;
    final g = d.consultation;
    // Première condition manquante, avec le geste qui la lève.
    final blocage = !g.autorise ? g.message : null;
    final approbationBloquee = blocage != null || a.paiementBloquant != null || a.signatureManquante;
    final rappel =
        blocage ??
        (a.peutApprouver && a.signatureManquante
            ? 'Signature manquante : ajoutez-la dans votre profil DG Flow (web).'
            : a.peutApprouver && a.paiementBloquant != null
            ? 'Paiement incohérent : approbation impossible, renvoyez le document.'
            : null);
    final leverBlocage = !g.tableauOk && g.documentOk && d.tableau != null ? onOuvrirTableau : null;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(top: BorderSide(color: p.bordure)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.sombre ? 0.3 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Espace.l, Espace.m, Espace.l, Espace.s),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  child: decide && rappel != null
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: Espace.s),
                          child: Material(
                            color: p.alerteFond,
                            borderRadius: BorderRadius.circular(Rayon.s + 2),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(Rayon.s + 2),
                              onTap: leverBlocage,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: Espace.m, vertical: Espace.s),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_rounded, size: 18, color: p.alerte),
                                    const SizedBox(width: Espace.s),
                                    Expanded(
                                      child: Text(rappel, style: Typo.secondaire.copyWith(color: p.texte)),
                                    ),
                                    if (leverBlocage != null) ...[
                                      const SizedBox(width: Espace.s),
                                      Text('Ouvrir', style: Typo.libelle.copyWith(fontSize: 14, color: p.action)),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                if (a.peutRepondreInfo)
                  Padding(
                    padding: EdgeInsets.only(bottom: a.peutApprouver || a.peutRejeter ? Espace.s : 0),
                    child: FilledButton.icon(
                      onPressed: () => onDecider(ModeDecision.reponse),
                      icon: const Icon(Icons.forum_outlined),
                      label: const Text('Répondre à la demande'),
                    ),
                  ),
                if (a.peutApprouver || a.peutRejeter)
                  Row(
                    children: [
                      if (a.peutRejeter)
                        Expanded(
                          flex: 10,
                          child: BoutonRefus(
                            libelle: a.rejetAvecDestinataire ? 'Renvoyer' : 'Rejeter',
                            onPressed: blocage != null ? null : () => onDecider(ModeDecision.rejeter),
                          ),
                        ),
                      if (a.peutRejeter && a.peutApprouver) const SizedBox(width: Espace.m),
                      if (a.peutApprouver)
                        Expanded(
                          flex: 14,
                          child: BoutonApprobation(
                            libelle: 'Approuver',
                            onPressed: approbationBloquee ? null : () => onDecider(ModeDecision.approuver),
                          ),
                        ),
                    ],
                  ),
                if (a.peutDemanderInfo || a.peutConvertirBc || a.peutAnnulerBc)
                  Padding(
                    padding: const EdgeInsets.only(top: Espace.xs),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: Espace.l,
                      children: [
                        if (a.peutDemanderInfo)
                          TextButton.icon(
                            onPressed: () => onDecider(ModeDecision.info),
                            icon: const Icon(Icons.help_outline_rounded, size: 19),
                            label: const Text('Demander une information'),
                          ),
                        if (a.peutConvertirBc || a.peutAnnulerBc)
                          TextButton.icon(
                            onPressed: a.peutConvertirBc && approbationBloquee
                                ? null
                                : () => onDecider(a.peutConvertirBc ? ModeDecision.bc : ModeDecision.annulerBc),
                            icon: const Icon(Icons.receipt_long_outlined, size: 19),
                            label: Text(a.peutConvertirBc ? 'Bon de commande' : 'Annuler le bon de commande'),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
