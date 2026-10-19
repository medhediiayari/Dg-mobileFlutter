import 'package:flutter/material.dart';

import '../theme.dart';

/// Reflet qui balaie les silhouettes pendant le premier chargement.
class Miroitement extends StatefulWidget {
  const Miroitement({required this.child, super.key});

  final Widget child;

  @override
  State<Miroitement> createState() => _MiroitementState();
}

class _MiroitementState extends State<Miroitement> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final reflet = context.sombre ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.75);
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, enfant) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (r) {
          final x = -r.width + _c.value * r.width * 3;
          return LinearGradient(
            colors: [p.squelette.withValues(alpha: 0), reflet, p.squelette.withValues(alpha: 0)],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(Rect.fromLTWH(x - r.width, 0, r.width * 2, r.height));
        },
        child: enfant,
      ),
    );
  }
}

/// Os d'une silhouette.
class Os extends StatelessWidget {
  const Os({this.largeur, this.hauteur = 12, this.rayon = 5, this.facteur, super.key});

  final double? largeur;
  final double hauteur;
  final double rayon;

  /// Largeur relative au parent (0..1).
  final double? facteur;

  @override
  Widget build(BuildContext context) {
    final os = Container(
      width: largeur,
      height: hauteur,
      decoration: BoxDecoration(color: context.dg.squelette, borderRadius: BorderRadius.circular(rayon)),
    );
    return facteur == null
        ? os
        : FractionallySizedBox(widthFactor: facteur, alignment: Alignment.centerLeft, child: os);
  }
}

/// Silhouette d'une carte RC.
class CarteSquelette extends StatelessWidget {
  const CarteSquelette({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    return Container(
      margin: const EdgeInsets.only(bottom: Espace.m),
      padding: const EdgeInsets.all(Espace.l),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Rayon.l),
        border: Border.all(color: p.bordure),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Os(largeur: 34, hauteur: 18), SizedBox(width: 8), Os(largeur: 130, hauteur: 12)]),
          SizedBox(height: 14),
          Os(facteur: 0.72, hauteur: 18),
          SizedBox(height: 8),
          Os(facteur: 0.5, hauteur: 12),
          SizedBox(height: 16),
          Os(facteur: 1, hauteur: 24, rayon: 4),
          SizedBox(height: 12),
          Os(facteur: 0.4, hauteur: 12),
        ],
      ),
    );
  }
}

/// Liste de silhouettes de cartes.
class ListeSquelette extends StatelessWidget {
  const ListeSquelette({this.nombre = 3, this.padding = const EdgeInsets.all(Espace.l), super.key});

  final int nombre;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Chargement',
    child: Miroitement(
      child: Padding(
        padding: padding,
        child: Column(children: [for (var i = 0; i < nombre; i++) const CarteSquelette()]),
      ),
    ),
  );
}

/// Silhouette de la fiche d'un document.
class FicheSquelette extends StatelessWidget {
  const FicheSquelette({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    Widget bloc(double h) => Container(
      height: h,
      margin: const EdgeInsets.only(bottom: Espace.l),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Rayon.l),
        border: Border.all(color: p.bordure),
      ),
    );
    return Semantics(
      label: 'Chargement',
      child: Miroitement(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: p.surface,
              padding: const EdgeInsets.all(Espace.l),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Os(largeur: 60, hauteur: 18),
                  SizedBox(height: 12),
                  Os(facteur: 0.8, hauteur: 22),
                  SizedBox(height: 8),
                  Os(facteur: 0.55, hauteur: 13),
                  SizedBox(height: 18),
                  Os(facteur: 1, hauteur: 34, rayon: 4),
                  SizedBox(height: 10),
                  Os(facteur: 0.4, hauteur: 13),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Espace.l),
              child: Column(children: [bloc(44), bloc(150), bloc(170)]),
            ),
          ],
        ),
      ),
    );
  }
}
