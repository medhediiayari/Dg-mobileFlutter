import 'package:flutter/material.dart';

import '../theme.dart';

/// Logo DG Flow du web : `dgflow-logo-fond-blanc.png` sur fond clair,
/// `dgflow-sidebar.png` (« DG » blanc) sur le marine et en mode sombre.
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

/// Bandeau « Mode démonstration » : pastille ambre du web
/// (`rounded-full border bg-amber-100 text-amber-800 border-amber-300`).
class BandeauDemo extends StatelessWidget {
  const BandeauDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.dg.ambre;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: a.fond,
        border: Border.all(color: a.bord),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('Démonstration, données fictives', style: Typo.sigle.copyWith(color: a.texte)),
    );
  }
}
