import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/commun.dart';
import '../theme.dart';

/// Carte du web (shadcn `Card`) : `rounded-xl border bg-white shadow-sm`.
/// [bordGauche] : liseré `border-l-4` des cartes RC (couleur de l'état).
class Carte extends StatelessWidget {
  const Carte({
    required this.child,
    this.padding = const EdgeInsets.all(Espace.l),
    this.couleurBord,
    this.epaisseurBord = 1,
    this.bordGauche,
    this.ombre = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? couleurBord;
  final double epaisseurBord;
  final Color? bordGauche;
  final bool ombre;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final contenu = Padding(padding: padding, child: child);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Rayon.l),
        border: Border.all(color: couleurBord ?? p.bordure, width: epaisseurBord),
        boxShadow: ombre && !context.sombre ? OmbreWeb.sm : null,
      ),
      child: bordGauche == null
          ? contenu
          : ClipRRect(
              borderRadius: BorderRadius.circular(Rayon.l - epaisseurBord),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: bordGauche!, width: 4)),
                ),
                child: contenu,
              ),
            ),
    );
  }
}

/// Pastille de statut, comme les `Badge` des écrans de validation du web :
/// `bg-*-100 text-*-800 border-*-300 font-semibold`, icône `w-3 h-3`.
/// La couleur vient du ton fourni par l'API, ou d'une [teinte] explicite.
class Pastille extends StatelessWidget {
  const Pastille({
    required this.libelle,
    this.ton = Ton.neutre,
    this.teinte,
    this.petite = false,
    this.icone,
    this.pilule = false,
    super.key,
  });

  final String libelle;
  final Ton ton;
  final Teinte? teinte;
  final bool petite;
  final IconData? icone;

  /// `rounded-full` (puces de rôle, états de projet) au lieu de `rounded-md`.
  final bool pilule;

  @override
  Widget build(BuildContext context) {
    final c = teinte ?? context.dg.ton(ton);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: petite ? 6 : 8, vertical: petite ? 1.5 : 2.5),
        decoration: BoxDecoration(
          color: c.fond,
          border: Border.all(color: c.bord),
          borderRadius: BorderRadius.circular(pilule ? 999 : Rayon.s),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              if (icone != null)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(icone, size: petite ? 11 : 12, color: c.texte),
                  ),
                ),
              TextSpan(text: libelle),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Typo.sigle.copyWith(color: c.texte, fontSize: petite ? 11 : 12),
        ),
      ),
    );
  }
}

/// « RC » (bleu `#0061A7`) / « Avenant 2 » (teal, la couleur des avenants sur le web).
class TagType extends StatelessWidget {
  const TagType({required this.avenant, this.numero, this.grand = false, super.key});

  final bool avenant;
  final int? numero;
  final bool grand;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final t = avenant ? p.teal : p.bleu;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: grand ? 8 : 6, vertical: grand ? 2.5 : 1.5),
      decoration: BoxDecoration(
        color: t.fond,
        border: Border.all(color: t.bord),
        borderRadius: BorderRadius.circular(Rayon.s),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(avenant ? LucideIcons.layers : LucideIcons.fileText, size: grand ? 13 : 12, color: avenant ? t.texte : p.action),
          const SizedBox(width: 4),
          Text(
            avenant ? 'Avenant ${numero ?? ''}'.trim() : 'RC',
            style: Typo.sigle.copyWith(
              color: avenant ? t.texte : p.action,
              fontWeight: FontWeight.w700,
              fontSize: grand ? 13 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section : intitulé `font-bold text-[#172D4C]` (icône `text-[#0061A7]`), contenu sur carte.
class Section extends StatelessWidget {
  const Section({
    required this.titre,
    required this.child,
    this.droite,
    this.nu = false,
    this.padding,
    this.icone,
    super.key,
  });

  final String titre;
  final Widget child;
  final Widget? droite;

  /// Sans carte (contenu déjà composé de cartes).
  final bool nu;
  final EdgeInsetsGeometry? padding;
  final IconData? icone;

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (icone != null) ...[
                    Icon(icone, size: 18, color: p.action),
                    const SizedBox(width: Espace.s),
                  ],
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(titre, style: Typo.libelle.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: p.titre)),
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

/// Ligne libellé / valeur (« Créé le : » `text-gray-600 font-medium`, valeur
/// `font-semibold text-gray-900`) ; « — » si la valeur manque.
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
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: derniere ? null : Border(bottom: BorderSide(color: p.bordure)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 10,
              child: Text(libelle, style: Typo.secondaire.copyWith(color: p.texteSecondaire, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: Espace.m),
            Expanded(
              flex: 12,
              child: SelectableText(
                v,
                textAlign: TextAlign.right,
                style: (fort ? Typo.montant.copyWith(fontWeight: FontWeight.w700) : Typo.secondaire.copyWith(fontWeight: FontWeight.w600))
                    .copyWith(color: couleur ?? (fort ? p.titre : p.texte)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bandeau teinté du web : `p-3 bg-*-50 border border-*-200 rounded-lg`, icône
/// `text-*-600`, texte `text-*-800` (motif de rejet, demande d'information,
/// message du valideur…). [fort] : `border-2 border-*-300` (demande reçue).
class Bandeau extends StatelessWidget {
  const Bandeau({
    required this.icone,
    required this.titre,
    this.ton = Ton.info,
    this.teinte,
    this.child,
    this.action,
    this.fort = false,
    super.key,
  });

  final Ton ton;
  final Teinte? teinte;
  final IconData icone;
  final String titre;
  final Widget? child;
  final Widget? action;
  final bool fort;

  @override
  Widget build(BuildContext context) {
    final c = teinte ?? context.dg.ton(ton);
    return Container(
      margin: const EdgeInsets.only(bottom: Espace.m),
      padding: const EdgeInsets.all(Espace.m),
      decoration: BoxDecoration(
        color: c.fondDoux,
        border: Border.all(color: fort ? c.bord : c.bordDoux, width: fort ? 2 : 1),
        borderRadius: BorderRadius.circular(Rayon.m),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icone, size: 18, color: c.vif),
          ),
          const SizedBox(width: Espace.s + 2),
          Expanded(
            child: DefaultTextStyle.merge(
              style: Typo.secondaire.copyWith(color: c.texte),
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
          ),
        ],
      ),
    );
  }
}

/// État vide du web : `py-12 bg-gray-50 rounded-xl border border-dashed
/// border-gray-300`, cercle `w-16 h-16 bg-gray-100`, icône `text-gray-400`.
class EtatVide extends StatelessWidget {
  const EtatVide({required this.icone, required this.titre, this.texte, this.action, super.key});

  final IconData icone;
  final String titre;
  final String? texte;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    return Padding(
      padding: const EdgeInsets.all(Espace.l),
      child: CustomPaint(
        painter: _BordPointille(couleur: p.bordureForte, rayon: Rayon.l),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: Espace.xl, vertical: 48),
          decoration: BoxDecoration(
            color: context.sombre ? p.surface : p.gris.fondDoux,
            borderRadius: BorderRadius.circular(Rayon.l),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: p.gris.fond, shape: BoxShape.circle),
                child: Icon(icone, size: 30, color: p.texteDiscret),
              ),
              const SizedBox(height: Espace.l),
              Text(
                titre,
                textAlign: TextAlign.center,
                style: Typo.sousTitre.copyWith(color: p.texte, fontWeight: FontWeight.w500),
              ),
              if (texte != null) ...[
                const SizedBox(height: Espace.xs),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    texte!,
                    textAlign: TextAlign.center,
                    style: Typo.secondaire.copyWith(color: p.texteTertiaire),
                  ),
                ),
              ],
              if (action != null) ...[const SizedBox(height: Espace.l), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class _BordPointille extends CustomPainter {
  const _BordPointille({required this.couleur, required this.rayon});

  final Color couleur;
  final double rayon;

  @override
  void paint(Canvas canvas, Size size) {
    final chemin = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(rayon)).deflate(0.5));
    final pinceau = Paint()
      ..color = couleur
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final m in chemin.computeMetrics()) {
      for (double d = 0; d < m.length; d += 7) {
        canvas.drawPath(m.extractPath(d, d + 4), pinceau);
      }
    }
  }

  @override
  bool shouldRepaint(_BordPointille old) => old.couleur != couleur || old.rayon != rayon;
}

/// Erreur avec « Réessayer ».
class EtatErreur extends StatelessWidget {
  const EtatErreur({required this.message, this.onReessayer, this.icone = LucideIcons.cloudOff, super.key});

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
            CercleIcone(teinte: p.rouge, icone: icone, taille: 64, tailleIcone: 28),
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
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: const Text('Réessayer'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(170, 48)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Cercle d'icône teinté : en-têtes des dialogues de décision (`w-12 h-12
/// rounded-full bg-green-100` + icône `text-green-600`), étapes du parcours.
class CercleIcone extends StatelessWidget {
  const CercleIcone({required this.teinte, required this.icone, this.taille = 48, this.tailleIcone = 22, super.key});

  final Teinte teinte;
  final IconData icone;
  final double taille;
  final double tailleIcone;

  @override
  Widget build(BuildContext context) => Container(
    width: taille,
    height: taille,
    decoration: BoxDecoration(color: teinte.fond, shape: BoxShape.circle),
    child: Icon(icone, size: tailleIcone, color: teinte.vif),
  );
}

/// Compteur rond des onglets (`min-w-[20px] h-5 rounded-full text-xs font-bold`) :
/// `bg-[#0061A7] text-white` actif, `bg-gray-300 text-gray-600` sinon.
class Compteur extends StatelessWidget {
  const Compteur({required this.valeur, this.actif = false, this.surFonce = false, super.key});

  final int valeur;
  final bool actif;

  /// Posé sur un fond `#0061A7` (puce active) : blanc translucide.
  final bool surFonce;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final fond = surFonce ? Colors.white.withValues(alpha: 0.22) : (actif ? p.action : p.gris.bord);
    final texte = surFonce || actif ? Colors.white : p.gris.vif;
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(999)),
      child: Text(
        valeur > 99 ? '99+' : '$valeur',
        style: Typo.petit.copyWith(color: texte, fontWeight: FontWeight.w700, height: 1),
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
    final fond = actif ? p.action : p.surface;
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
                constraints: const BoxConstraints(minHeight: 36),
                child: Padding(
                  padding: EdgeInsets.only(left: 14, right: compteur != null ? 8 : 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        libelle,
                        style: Typo.libelle.copyWith(color: actif ? p.surAction : p.texteSecondaire),
                      ),
                      if (compteur != null) ...[
                        const SizedBox(width: 6),
                        Compteur(valeur: compteur!, surFonce: actif),
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

/// Onglets du web (Service Gestion) : `p-1 rounded-lg bg-gray-100 border
/// border-gray-200`, actif `bg-white text-[#0061A7] shadow-sm`, inactif `text-gray-500`.
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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surfaceRelief,
        border: Border.all(color: p.bordure),
        borderRadius: BorderRadius.circular(Rayon.m),
      ),
      child: LayoutBuilder(
        builder: (context, contraintes) {
          final largeur = contraintes.maxWidth / options.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                left: largeur * index,
                top: 0,
                bottom: 0,
                width: largeur,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.sombre ? p.surfaceRelief : p.surface,
                    border: context.sombre ? Border.all(color: p.bordureForte) : null,
                    borderRadius: BorderRadius.circular(Rayon.s),
                    boxShadow: context.sombre ? null : OmbreWeb.sm,
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
                          borderRadius: BorderRadius.circular(Rayon.s),
                          onTap: () => onChange(v),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 40),
                            child: Center(
                              child: Text(
                                libelle,
                                style: Typo.libelle.copyWith(
                                  color: v == valeur ? p.action : p.texteTertiaire,
                                  fontWeight: v == valeur ? FontWeight.w600 : FontWeight.w500,
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

/// « Approuver et signer » : `bg-gradient-to-r from-green-600 to-green-700
/// text-white font-semibold shadow-md`, icône CheckCircle.
class BoutonApprobation extends StatelessWidget {
  const BoutonApprobation({
    required this.libelle,
    required this.onPressed,
    this.icone = LucideIcons.checkCircle,
    this.chargement = false,
    super.key,
  });

  final String libelle;
  final VoidCallback? onPressed;
  final IconData icone;
  final bool chargement;

  @override
  Widget build(BuildContext context) {
    final actif = onPressed != null && !chargement;
    return Opacity(
      opacity: actif || chargement ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // Mêmes verts en mode sombre : le texte blanc doit rester lisible.
          gradient: const LinearGradient(colors: [Tw.green600, Tw.green700]),
          borderRadius: BorderRadius.circular(Rayon.s),
          boxShadow: actif && !context.sombre ? OmbreWeb.md : null,
        ),
        child: FilledButton.icon(
          onPressed: chargement ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            shadowColor: Colors.transparent,
          ),
          icon: chargement ? const Roue(couleur: Colors.white) : Icon(icone, size: 18),
          label: Text(libelle, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

/// Bouton contour coloré des cartes RC : `border-2 border-*-300 text-*-600
/// font-semibold` (Rejeter rouge, Demande d'information ambre, Consulter bleu,
/// Tableau indigo, Avenants teal, Suivre violet, Fichiers orange).
class BoutonContour extends StatelessWidget {
  const BoutonContour({required this.teinte, required this.libelle, required this.onPressed, this.icone, super.key});

  final Teinte teinte;
  final String libelle;
  final VoidCallback? onPressed;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final style = OutlinedButton.styleFrom(
      foregroundColor: teinte.vif,
      backgroundColor: p.surface,
      side: BorderSide(color: onPressed == null ? p.bordure : teinte.bord, width: 2),
      overlayColor: teinte.fondDoux,
    );
    final texte = Text(libelle, maxLines: 1, overflow: TextOverflow.ellipsis);
    return icone == null
        ? OutlinedButton(onPressed: onPressed, style: style, child: texte)
        : OutlinedButton.icon(onPressed: onPressed, style: style, icon: Icon(icone, size: 18), label: texte);
  }
}

/// « Rejeter » / « Renvoyer » : contour rouge, icône XCircle.
class BoutonRefus extends StatelessWidget {
  const BoutonRefus({required this.libelle, required this.onPressed, this.icone = LucideIcons.xCircle, super.key});

  final String libelle;
  final VoidCallback? onPressed;
  final IconData icone;

  @override
  Widget build(BuildContext context) =>
      BoutonContour(teinte: context.dg.rouge, libelle: libelle, onPressed: onPressed, icone: icone);
}

/// Bouton plein de confirmation : « Confirmer le rejet » (`bg-red-600`),
/// « Envoyer la demande » (`bg-amber-600`), « Convertir et approuver » (`#0061A7`)…
class BoutonPlein extends StatelessWidget {
  const BoutonPlein({
    required this.couleur,
    required this.libelle,
    required this.onPressed,
    this.icone,
    this.chargement = false,
    super.key,
  });

  final Color couleur;
  final String libelle;
  final VoidCallback? onPressed;
  final IconData? icone;
  final bool chargement;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: couleur,
      foregroundColor: Colors.white,
      disabledBackgroundColor: couleur.withValues(alpha: 0.5),
      disabledForegroundColor: Colors.white.withValues(alpha: 0.9),
    );
    final texte = Text(libelle, maxLines: 1, overflow: TextOverflow.ellipsis);
    if (icone == null && !chargement) return FilledButton(onPressed: onPressed, style: style, child: texte);
    return FilledButton.icon(
      onPressed: chargement ? null : onPressed,
      style: style,
      icon: chargement ? const Roue(couleur: Colors.white) : Icon(icone, size: 18),
      label: texte,
    );
  }
}

/// Fond des en-têtes de page RC : `bg-gradient-to-r from-[#172D4C] to-[#1e3d6b]`
/// (à passer en `flexibleSpace` d'une AppBar).
class DegradeEnTete extends StatelessWidget {
  const DegradeEnTete({super.key});

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(gradient: LinearGradient(colors: [Marque.marine, Marque.marineDegrade])),
  );
}

/// Petite roue de chargement (`Loader2` / `border-b-2 border-[#0061A7]`).
class Roue extends StatelessWidget {
  const Roue({this.couleur, this.taille = 18, super.key});

  final Color? couleur;
  final double taille;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: taille,
    child: CircularProgressIndicator(strokeWidth: 2.2, color: couleur ?? context.dg.action),
  );
}

/// Message d'erreur d'un formulaire : `p-3 bg-red-50 border border-red-200
/// rounded-md`, AlertCircle et texte `text-red-600 text-sm`.
class EncartErreur extends StatelessWidget {
  const EncartErreur({required this.message, this.action, super.key});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final r = context.dg.rouge;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(Espace.m),
        margin: const EdgeInsets.only(bottom: Espace.m),
        decoration: BoxDecoration(
          color: r.fondDoux,
          border: Border.all(color: r.bordDoux),
          borderRadius: BorderRadius.circular(Rayon.s),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(LucideIcons.alertCircle, size: 16, color: r.vif),
            ),
            const SizedBox(width: Espace.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: Typo.secondaire.copyWith(color: r.vif, fontWeight: FontWeight.w500),
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

/// Bouton de lien discret (« Ouvrir ») : `text-[#0061A7] font-semibold` sur `bg-blue-50`.
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rayon.s),
          side: BorderSide(color: p.bleu.bordDoux),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Rayon.s),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 34, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                widthFactor: 1,
                child: Text(libelle, style: Typo.libelle.copyWith(color: p.action)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
