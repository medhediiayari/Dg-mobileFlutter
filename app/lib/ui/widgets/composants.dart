import 'package:flutter/material.dart';

import '../../core/models/commun.dart';
import '../theme.dart';

/// Surface blanche à bord fin.
class Carte extends StatelessWidget {
  const Carte({
    required this.child,
    this.padding = const EdgeInsets.all(Espace.l),
    this.couleurBord,
    this.epaisseurBord = 1,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? couleurBord;
  final double epaisseurBord;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Rayon.l),
        border: Border.all(color: couleurBord ?? p.bordure, width: epaisseurBord),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Pastille de statut (ton fourni par l'API).
class Pastille extends StatelessWidget {
  const Pastille({required this.libelle, required this.ton, this.petite = false, this.icone, super.key});

  final String libelle;
  final Ton ton;
  final bool petite;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final c = context.dg.ton(ton);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 190),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: petite ? 8 : 10, vertical: petite ? 2.5 : 4),
        decoration: BoxDecoration(color: c.fond, borderRadius: BorderRadius.circular(999)),
        child: Text.rich(
          TextSpan(
            children: [
              if (icone != null)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(icone, size: petite ? 13 : 15, color: c.texte),
                  ),
                ),
              TextSpan(text: libelle),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Typo.petit.copyWith(color: c.texte, fontWeight: FontWeight.w600, fontSize: petite ? 12 : 13),
        ),
      ),
    );
  }
}

/// « RC » / « Avenant 2 ».
class TagType extends StatelessWidget {
  const TagType({required this.avenant, this.numero, this.grand = false, super.key});

  final bool avenant;
  final int? numero;
  final bool grand;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final couleur = avenant ? p.alerte : p.action;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: grand ? 8 : 7, vertical: 2),
      decoration: BoxDecoration(
        color: avenant ? p.alerteFond : p.accentClair,
        borderRadius: BorderRadius.circular(Rayon.s),
      ),
      child: Text(
        avenant ? 'Avenant ${numero ?? ''}'.trim() : 'RC',
        style: Typo.sigle.copyWith(color: couleur, fontSize: grand ? 14 : 13),
      ),
    );
  }
}

/// Section : intitulé en casse normale, contenu sur carte.
class Section extends StatelessWidget {
  const Section({required this.titre, required this.child, this.droite, this.nu = false, this.padding, super.key});

  final String titre;
  final Widget child;
  final Widget? droite;

  /// Sans carte (contenu déjà composé de cartes).
  final bool nu;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Espace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2, right: 2, bottom: Espace.s),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(titre, style: Typo.libelle.copyWith(color: p.texte)),
                    ),
                  ),
                  if (droite != null) ...[
                    const SizedBox(width: Espace.s),
                    Flexible(
                      child: Align(alignment: Alignment.centerRight, child: droite),
                    ),
                  ],
                ],
              ),
            ),
            if (nu)
              child
            else
              Carte(
                padding: padding ?? const EdgeInsets.symmetric(horizontal: Espace.l),
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}

/// Ligne libellé / valeur ; « — » si la valeur manque.
class LigneInfo extends StatelessWidget {
  const LigneInfo({
    required this.libelle,
    required this.valeur,
    this.fort = false,
    this.couleur,
    this.derniere = false,
    super.key,
  });

  final String libelle;
  final String? valeur;
  final bool fort;
  final Color? couleur;
  final bool derniere;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final v = valeur == null || valeur!.isEmpty ? '—' : valeur!;
    // Libellé et valeur lus d'un seul tenant par les lecteurs d'écran.
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: derniere ? null : Border(bottom: BorderSide(color: p.bordure)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 10,
              child: Text(libelle, style: Typo.secondaire.copyWith(color: p.texteSecondaire)),
            ),
            const SizedBox(width: Espace.m),
            Expanded(
              flex: 12,
              child: SelectableText(
                v,
                textAlign: TextAlign.right,
                style: (fort ? Typo.montant : Typo.corps.copyWith(fontSize: 15.5)).copyWith(color: couleur ?? p.texte),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bandeau tonal : motif de renvoi, demande d'information, message reçu…
class Bandeau extends StatelessWidget {
  const Bandeau({required this.ton, required this.icone, required this.titre, this.child, this.action, super.key});

  final Ton ton;
  final IconData icone;
  final String titre;
  final Widget? child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.dg.ton(ton);
    return Container(
      margin: const EdgeInsets.only(bottom: Espace.m),
      padding: const EdgeInsets.all(Espace.m + 2),
      decoration: BoxDecoration(color: c.fond, borderRadius: BorderRadius.circular(Rayon.m + 2)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icone, size: 20, color: c.texte),
          ),
          const SizedBox(width: Espace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: Typo.libelle.copyWith(color: c.texte)),
                if (child != null) Padding(padding: const EdgeInsets.only(top: 3), child: child),
                if (action != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Espace.s),
                    child: action,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// État vide : une direction, pas une ambiance.
class EtatVide extends StatelessWidget {
  const EtatVide({required this.icone, required this.titre, this.texte, this.action, super.key});

  final IconData icone;
  final String titre;
  final String? texte;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Espace.xxl, vertical: Espace.xxl + 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(color: p.accentClair, shape: BoxShape.circle),
              child: Icon(icone, size: 32, color: p.chevronMoyen),
            ),
            const SizedBox(height: Espace.l),
            Text(
              titre,
              textAlign: TextAlign.center,
              style: Typo.sousTitre.copyWith(color: p.texte),
            ),
            if (texte != null) ...[
              const SizedBox(height: Espace.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  texte!,
                  textAlign: TextAlign.center,
                  style: Typo.secondaire.copyWith(color: p.texteSecondaire),
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: Espace.l), action!],
          ],
        ),
      ),
    );
  }
}

/// Erreur avec « Réessayer ».
class EtatErreur extends StatelessWidget {
  const EtatErreur({required this.message, this.onReessayer, this.icone = Icons.cloud_off_rounded, super.key});

  final String message;
  final VoidCallback? onReessayer;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Espace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(color: p.dangerFond, shape: BoxShape.circle),
              child: Icon(icone, size: 30, color: p.danger),
            ),
            const SizedBox(height: Espace.l),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 330),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Typo.corps.copyWith(color: p.texte),
              ),
            ),
            if (onReessayer != null) ...[
              const SizedBox(height: Espace.l),
              OutlinedButton.icon(
                onPressed: onReessayer,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(170, 50)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Puce de filtre (état, type) avec compteur.
class Puce extends StatelessWidget {
  const Puce({required this.libelle, required this.actif, required this.onTap, this.compteur, super.key});

  final String libelle;
  final bool actif;
  final int? compteur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final fond = actif ? (context.sombre ? p.chevronProfond : p.marine) : p.surface;
    return Padding(
      padding: const EdgeInsets.only(right: Espace.s),
      child: Semantics(
        button: true,
        selected: actif,
        child: ZoneTactile(
          onTap: onTap,
          child: Material(
            color: fond,
            shape: StadiumBorder(side: BorderSide(color: actif ? fond : p.bordure)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        libelle,
                        style: Typo.libelle.copyWith(fontSize: 14, color: actif ? Colors.white : p.texteSecondaire),
                      ),
                      if (compteur != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '$compteur',
                          style: Typo.montant.copyWith(
                            fontSize: 14.5,
                            color: actif ? p.surMarineDoux : p.texteTertiaire,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Zone de toucher d'au moins 48 × 48 autour d'un élément visuellement plus petit.
class ZoneTactile extends StatelessWidget {
  const ZoneTactile({required this.child, required this.onTap, super.key});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
      child: Center(widthFactor: 1, child: child),
    ),
  );
}

/// Bascule à deux ou trois options, indicateur glissant.
class Segment<T> extends StatelessWidget {
  const Segment({required this.options, required this.valeur, required this.onChange, super.key});

  final List<(T, String)> options;
  final T valeur;
  final ValueChanged<T> onChange;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final index = options.indexWhere((o) => o.$1 == valeur);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: p.surfaceRelief, borderRadius: BorderRadius.circular(Rayon.m + 2)),
      child: LayoutBuilder(
        builder: (context, contraintes) {
          final largeur = contraintes.maxWidth / options.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: largeur * index,
                top: 0,
                bottom: 0,
                width: largeur,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.sombre ? p.chevronClair : p.surface,
                    borderRadius: BorderRadius.circular(Rayon.m - 1),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1)),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final (v, libelle) in options)
                    Expanded(
                      child: Semantics(
                        selected: v == valeur,
                        button: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(Rayon.m - 1),
                          onTap: () => onChange(v),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 44),
                            child: Center(
                              child: Text(
                                libelle,
                                style: Typo.libelle.copyWith(
                                  color: v == valeur ? (context.sombre ? p.texte : p.marine) : p.texteSecondaire,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Bouton plein vert « Approuver ».
class BoutonApprobation extends StatelessWidget {
  const BoutonApprobation({
    required this.libelle,
    required this.onPressed,
    this.icone = Icons.check_circle_outline_rounded,
    this.chargement = false,
    super.key,
  });

  final String libelle;
  final VoidCallback? onPressed;
  final IconData icone;
  final bool chargement;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    return FilledButton.icon(
      onPressed: chargement ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: p.approbation,
        foregroundColor: Colors.white,
        disabledBackgroundColor: p.approbation.withValues(alpha: context.sombre ? 0.22 : 0.35),
        disabledForegroundColor: Colors.white.withValues(alpha: context.sombre ? 0.4 : 0.85),
      ),
      icon: chargement ? const _Roue(couleur: Colors.white) : Icon(icone),
      label: Text(libelle, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

/// Bouton contour rouge « Rejeter » / « Renvoyer ».
class BoutonRefus extends StatelessWidget {
  const BoutonRefus({required this.libelle, required this.onPressed, this.icone = Icons.undo_rounded, super.key});

  final String libelle;
  final VoidCallback? onPressed;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: p.danger,
        side: BorderSide(color: onPressed == null ? p.bordure : p.danger.withValues(alpha: 0.45)),
      ),
      icon: Icon(icone),
      label: Text(libelle, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _Roue extends StatelessWidget {
  const _Roue({required this.couleur});

  final Color couleur;

  @override
  Widget build(BuildContext context) =>
      SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: couleur));
}

/// Petite roue de chargement.
class Roue extends StatelessWidget {
  const Roue({this.couleur, this.taille = 20, super.key});

  final Color? couleur;
  final double taille;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: taille,
    child: CircularProgressIndicator(strokeWidth: 2.4, color: couleur ?? context.dg.action),
  );
}

/// Message d'erreur sous un formulaire.
class EncartErreur extends StatelessWidget {
  const EncartErreur({required this.message, this.action, super.key});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(Espace.m),
        margin: const EdgeInsets.only(bottom: Espace.m),
        decoration: BoxDecoration(color: p.dangerFond, borderRadius: BorderRadius.circular(Rayon.s + 2)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_rounded, size: 18, color: p.danger),
            const SizedBox(width: Espace.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: Typo.corps.copyWith(color: p.danger, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  ?action,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton de lien discret (« Ouvrir »).
class LienPilule extends StatelessWidget {
  const LienPilule({required this.libelle, required this.onTap, super.key});

  final String libelle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    return ZoneTactile(
      onTap: onTap,
      child: Material(
        color: p.accentClair,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                widthFactor: 1,
                child: Text(libelle, style: Typo.libelle.copyWith(fontSize: 14, color: p.action)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
