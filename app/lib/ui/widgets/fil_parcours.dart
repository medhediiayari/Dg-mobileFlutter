import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/utils/parcours.dart';
import '../theme.dart';

/// Le fil du parcours : les cinq étapes du circuit en chevrons, comme ceux du
/// logo DG Flow. Franchies en bleu moyen, en cours en bleu profond (orange si
/// le document a été renvoyé), à venir en bleu très pâle. Lors d'un renvoi, les
/// étapes qui avaient validé avant le renvoi passent en bleu clair : elles
/// devront revoir le document.
///
/// [anime] : à la première apparition, les chevrons s'allument un à un jusqu'à
/// l'étape en cours (désactivé si l'utilisateur réduit les animations).
class FilParcours extends StatefulWidget {
  const FilParcours({required this.statut, this.grand = false, this.anime = false, super.key});

  final String statut;
  final bool grand;
  final bool anime;

  @override
  State<FilParcours> createState() => _FilParcoursState();
}

class _FilParcoursState extends State<FilParcours> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: widget.anime ? 0 : 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.anime && _anim.value == 0) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _anim.value = 1;
      } else {
        _anim.forward();
      }
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final pos = positionParcours(widget.statut);
    final echelle = math.min(MediaQuery.textScalerOf(context).scale(1), 1.35);
    final h = (widget.grand ? 34.0 : 24.0) * echelle;
    final renvoiCouleur = context.sombre ? const Color(0xFFB8620F) : p.alerte;

    Color fond(int i) {
      if (pos.mode == ModeParcours.termine) return p.chevronMoyen;
      if (i < pos.index) return p.chevronMoyen;
      if (i == pos.index) {
        if (pos.mode == ModeParcours.renvoi) return renvoiCouleur;
        if (pos.mode == ModeParcours.brouillon) return p.texteTertiaire;
        return p.chevronProfond;
      }
      if (pos.mode == ModeParcours.renvoi && pos.origine != null && i <= pos.origine!) return p.chevronClair;
      return p.chevronVide;
    }

    Color encre(int i) {
      final f = fond(i);
      if (f == p.chevronVide) return p.encreChevronVide;
      if (f == p.chevronClair) return context.sombre ? p.texte : p.marine;
      return Colors.white;
    }

    return Semantics(
      label: 'Parcours : ${pos.phrase}',
      container: true,
      excludeSemantics: true,
      child: SizedBox(
        height: h,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            final t = Curves.easeOutCubic.transform(_anim.value);
            final n = etapesCircuit.length;
            return CustomPaint(
              painter: _PeintreFil(
                fonds: [
                  for (var i = 0; i < n; i++)
                    Color.lerp(p.chevronVide, fond(i), ((t * (n + 0.5)) - i).clamp(0.0, 1.0))!,
                ],
                encres: [
                  for (var i = 0; i < n; i++)
                    Color.lerp(p.encreChevronVide, encre(i), ((t * (n + 0.5)) - i).clamp(0.0, 1.0))!,
                ],
                courant: pos.mode == ModeParcours.termine ? -1 : pos.index,
                taille: (widget.grand ? 14.0 : 12.0) * echelle,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PeintreFil extends CustomPainter {
  _PeintreFil({required this.fonds, required this.encres, required this.courant, required this.taille});

  final List<Color> fonds;
  final List<Color> encres;
  final int courant;
  final double taille;

  @override
  void paint(Canvas canvas, Size size) {
    final n = etapesCircuit.length;
    final h = size.height;
    final pointe = (h * 0.4).roundToDouble();
    const ecart = 3.5;
    // Les chevrons s'emboîtent : chaque segment recouvre la pointe du précédent, moins l'écart.
    final w = (size.width + (pointe - ecart) * (n - 1)) / n;
    final pas = w - pointe + ecart;
    for (var i = 0; i < n; i++) {
      final x = i * pas;
      final chemin = Path()
        ..moveTo(x, 0)
        ..lineTo(x + w - pointe, 0)
        ..lineTo(x + w, h / 2)
        ..lineTo(x + w - pointe, h)
        ..lineTo(x, h);
      if (i > 0) chemin.lineTo(x + pointe, h / 2);
      chemin.close();
      final peinture = Paint()
        ..color = fonds[i]
        ..isAntiAlias = true;
      canvas.drawPath(chemin, peinture);
      // Contour de même couleur, joints arrondis : angles adoucis comme ceux du logo.
      canvas.drawPath(
        chemin,
        peinture
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeJoin = StrokeJoin.round,
      );

      final debut = x + (i == 0 ? 0 : pointe);
      final fin = x + w - pointe / 2;
      final texte = TextPainter(
        text: TextSpan(
          text: etapesCircuit[i].sigle,
          style: TextStyle(
            fontFamily: Polices.condensee,
            fontWeight: i == courant ? FontWeight.w700 : FontWeight.w600,
            fontSize: taille,
            height: 1,
            color: encres[i],
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: math.max(0, fin - debut));
      texte.paint(canvas, Offset(debut + (fin - debut - texte.width) / 2, (h - texte.height) / 2));
    }
  }

  @override
  bool shouldRepaint(_PeintreFil old) =>
      old.taille != taille || old.courant != courant || !_egales(old.fonds, fonds) || !_egales(old.encres, encres);

  static bool _egales(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Phrase de position vue par l'utilisateur, et sa couleur.
({String texte, IconData? icone, Color couleur, bool fort}) phrasePosition(
  BuildContext context, {
  required String statut,
  required bool decideur,
  required bool infoPourMoi,
}) {
  final p = context.dg;
  final pos = positionParcours(statut);
  if (infoPourMoi) {
    return (texte: 'Une information vous est demandée', icone: Icons.forum_rounded, couleur: p.action, fort: true);
  }
  if (decideur) {
    if (pos.mode == ModeParcours.brouillon) {
      return (
        texte: 'Brouillon à finaliser sur DG Flow web',
        icone: Icons.edit_note_rounded,
        couleur: p.texteSecondaire,
        fort: true,
      );
    }
    if (pos.mode == ModeParcours.renvoi && pos.origine != null) {
      return (
        texte:
            'Renvoyé par le ${etapesCircuit[pos.origine!].sigle}, ${pos.index == 0 ? 'à corriger sur DG Flow web' : 'à vous de reprendre'}',
        icone: Icons.undo_rounded,
        couleur: p.alerte,
        fort: true,
      );
    }
    return (texte: 'À vous de décider', icone: Icons.radio_button_checked_rounded, couleur: p.action, fort: true);
  }
  return (
    texte: pos.phrase,
    icone: pos.mode == ModeParcours.termine ? Icons.verified_rounded : null,
    couleur: pos.mode == ModeParcours.termine ? p.succes : p.texteSecondaire,
    fort: false,
  );
}
