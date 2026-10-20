import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/commun.dart';
import '../../core/utils/format.dart';
import '../telechargement.dart';
import '../theme.dart';

/// Icône Lucide d'un fichier, comme sur le web (FileText, Image, FileSpreadsheet, File).
IconData iconeFichier(String type) {
  if (type.contains('pdf')) return LucideIcons.fileText;
  if (type.startsWith('image/')) return LucideIcons.image;
  if (type.contains('sheet') || type.contains('excel') || type.contains('csv')) return LucideIcons.fileSpreadsheet;
  return LucideIcons.file;
}

/// Pièces jointes du circuit : téléchargées via l'API, ouvertes avec le lecteur du
/// téléphone. Ligne du web : `p-2 bg-white border rounded-lg`, FileText / Eye.
class ListePieces extends ConsumerStatefulWidget {
  const ListePieces({required this.rcId, required this.pieces, super.key});

  final int rcId;
  final List<PieceJointe> pieces;

  @override
  ConsumerState<ListePieces> createState() => _ListePiecesState();
}

class _ListePiecesState extends ConsumerState<ListePieces> {
  int? _enCours;
  double? _progression;

  Future<void> _ouvrir(PieceJointe piece) async {
    setState(() {
      _enCours = piece.id;
      _progression = null;
    });
    await telechargerEtOuvrir(
      context,
      ref,
      chemin: '/rc/${widget.rcId}/pieces/${piece.id}',
      nom: piece.nom,
      type: piece.type,
      progression: (v) {
        if (mounted) setState(() => _progression = v);
      },
    );
    if (mounted) setState(() => _enCours = null);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pieces.isEmpty) return const SizedBox.shrink();
    final p = context.dg;
    return Padding(
      padding: const EdgeInsets.only(top: Espace.s),
      child: Column(
        children: [
          for (final piece in widget.pieces)
            Padding(
              padding: const EdgeInsets.only(bottom: Espace.xs),
              child: Material(
                color: p.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Rayon.m),
                  side: BorderSide(color: p.bordure),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _enCours == null ? () => _ouvrir(piece) : null,
                  child: Semantics(
                    button: true,
                    label: 'Ouvrir ${piece.nom}',
                    excludeSemantics: true,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Espace.m, vertical: 10),
                        child: Row(
                          children: [
                            Icon(iconeFichier(piece.type), size: 18, color: p.action),
                            const SizedBox(width: Espace.s),
                            Expanded(
                              child: Text(
                                piece.nom,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Typo.secondaire.copyWith(color: p.texte, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(width: Espace.s),
                            if (_enCours == piece.id)
                              SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2.2, value: _progression),
                              )
                            else ...[
                              Text(Format.taille(piece.taille), style: Typo.petit.copyWith(color: p.texteTertiaire)),
                              const SizedBox(width: Espace.s),
                              Icon(LucideIcons.eye, size: 16, color: p.action),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
