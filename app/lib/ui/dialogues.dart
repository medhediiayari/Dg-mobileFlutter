import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'theme.dart';
import 'widgets/composants.dart';

Future<void> informer(BuildContext context, String titre, [String? message]) => showDialog<void>(
  context: context,
  builder: (c) => AlertDialog(
    title: Text(titre),
    content: message == null ? null : Text(message),
    actions: [FilledButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK'))],
  ),
);

/// Dialogue de confirmation du web : « Annuler » en contour, confirmation pleine
/// (`bg-red-600` si [destructif]).
Future<bool> confirmer(
  BuildContext context, {
  required String titre,
  required String message,
  required String libelleOk,
  bool destructif = false,
}) async {
  final p = context.dg;
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(titre),
      content: Text(message),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(c).pop(false),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          child: const Text('Annuler'),
        ),
        BoutonPlein(
          couleur: destructif ? p.rouge.vif : p.action,
          libelle: libelleOk,
          onPressed: () => Navigator.of(c).pop(true),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Toast du web (fond blanc, bord, ombre) ; l'icône prend la couleur de [teinte]
/// (succès émeraude par défaut, comme `CheckCircle2 text-emerald-500`).
void signaler(BuildContext context, String message, {IconData? icone, Teinte? teinte}) {
  final p = context.dg;
  final t = teinte ?? p.emeraude;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icone ?? LucideIcons.checkCircle2, color: t.plein, size: 20),
            const SizedBox(width: Espace.m),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
