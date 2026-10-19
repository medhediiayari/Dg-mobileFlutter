import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../core/api/api_exception.dart';
import '../core/providers.dart';
import 'dialogues.dart';

const String typeExcel = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

String _typeDuFichier(String chemin, String parDefaut) {
  final c = chemin.toLowerCase();
  if (c.endsWith('.pdf')) return 'application/pdf';
  if (c.endsWith('.csv')) return 'text/csv';
  if (c.endsWith('.xlsx')) return typeExcel;
  if (c.endsWith('.jpg') || c.endsWith('.jpeg')) return 'image/jpeg';
  if (c.endsWith('.png')) return 'image/png';
  return parDefaut;
}

/// Télécharge un fichier servi par l'API (pièce jointe, fichier du dossier,
/// classeur Excel) puis l'ouvre avec les applications du téléphone ; à défaut,
/// propose le partage. MinIO n'est jamais contacté directement.
Future<void> telechargerEtOuvrir(
  BuildContext context,
  WidgetRef ref, {
  required String chemin,
  required String nom,
  required String type,
  ValueChanged<double?>? progression,
}) async {
  try {
    final fichier = await ref
        .read(apiProvider)
        .telecharger(chemin, nom, progression: (fait, total) => progression?.call(total > 0 ? fait / total : null));
    final mime = _typeDuFichier(fichier.path, type);
    final ouvert = await OpenFilex.open(fichier.path, type: mime);
    if (ouvert.type != ResultType.done) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(fichier.path, mimeType: mime)],
          title: nom,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) await informer(context, 'Téléchargement impossible', messageErreur(e));
  }
}
