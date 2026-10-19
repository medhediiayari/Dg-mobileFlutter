import 'package:flutter/material.dart';

import '../theme.dart';

/// Logo DG Flow, version claire ou sombre selon le thème.
class LogoDgFlow extends StatelessWidget {
  const LogoDgFlow({this.hauteur = 44, this.surFonce = false, super.key});

  final double hauteur;

  /// Posé sur le marine : version claire quel que soit le thème.
  final bool surFonce;

  @override
  Widget build(BuildContext context) => Image.asset(
    surFonce || context.sombre ? 'assets/images/logo-dgflow-dark.png' : 'assets/images/logo-dgflow.png',
    height: hauteur,
    fit: BoxFit.contain,
    semanticLabel: 'DG Flow',
  );
}

/// Les trois chevrons du logo, en filigrane dans les en-têtes marine.
class ChevronsFiligrane extends StatelessWidget {
  const ChevronsFiligrane({this.opacite = 1, super.key});

  final double opacite;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _Chevrons(opacite: opacite),
      size: Size.infinite,
    ),
  );
}

class _Chevrons extends CustomPainter {
  const _Chevrons({required this.opacite});

  final double opacite;

  @override
  void paint(Canvas canvas, Size size) {
    // Trois chevrons croissants, ancrés en haut à droite et partiellement coupés.
    final h = size.height * 1.15;
    final base = size.width - h * 0.55;
    final couleurs = [
      const Color(0xFFA2BAE0).withValues(alpha: 0.06 * opacite),
      const Color(0xFF507EBC).withValues(alpha: 0.09 * opacite),
      const Color(0xFF1D539D).withValues(alpha: 0.24 * opacite),
    ];
    final tailles = [0.46, 0.66, 0.9];
    final decalages = [-h * 0.62, -h * 0.34, 0.0];
    for (var i = 0; i < 3; i++) {
      final t = h * tailles[i];
      final x = base + decalages[i];
      final y = (size.height - t) / 2 - size.height * 0.16;
      final e = t * 0.36; // épaisseur du chevron
      final chemin = Path()
        ..moveTo(x, y)
        ..lineTo(x + e, y)
        ..lineTo(x + e + t / 2, y + t / 2)
        ..lineTo(x + e, y + t)
        ..lineTo(x, y + t)
        ..lineTo(x + t / 2, y + t / 2)
        ..close();
      canvas.drawPath(
        chemin,
        Paint()
          ..color = couleurs[i]
          ..style = PaintingStyle.fill
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_Chevrons old) => old.opacite != opacite;
}

/// Bandeau « Mode démonstration ».
class BandeauDemo extends StatelessWidget {
  const BandeauDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: p.alerteFond, borderRadius: BorderRadius.circular(999)),
      child: Text(
        'Démonstration, données fictives',
        style: Typo.petit.copyWith(color: p.alerte, fontWeight: FontWeight.w600),
      ),
    );
  }
}
