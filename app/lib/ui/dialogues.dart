import 'package:flutter/material.dart';

import 'theme.dart';

Future<void> informer(BuildContext context, String titre, [String? message]) => showDialog<void>(
  context: context,
  builder: (c) => AlertDialog(
    title: Text(titre),
    content: message == null ? null : Text(message),
    actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK'))],
  ),
);

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
      actions: [
        TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Annuler')),
        TextButton(
          onPressed: () => Navigator.of(c).pop(true),
          style: destructif ? TextButton.styleFrom(foregroundColor: p.danger) : null,
          child: Text(libelleOk),
        ),
      ],
    ),
  );
  return r ?? false;
}

void signaler(BuildContext context, String message, {IconData? icone}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icone != null) ...[Icon(icone, color: Colors.white, size: 20), const SizedBox(width: Espace.m)],
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
