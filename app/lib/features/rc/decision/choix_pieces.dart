import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/commun.dart';
import '../../../core/utils/format.dart';
import '../../../ui/dialogues.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/liste_pieces.dart';

/// Mêmes limites que l'API (backend `modules/rc/pieces.ts`).
const int maxPieces = 10;
const int maxOctetsPiece = 25 * 1024 * 1024;

String typeMimeDepuisNom(String nom) {
  final ext = nom.contains('.') ? nom.split('.').last.toLowerCase() : '';
  return switch (ext) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'heic' => 'image/heic',
    'webp' => 'image/webp',
    'pdf' => 'application/pdf',
    'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'xls' => 'application/vnd.ms-excel',
    'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'doc' => 'application/msword',
    'txt' => 'text/plain',
    'csv' => 'text/csv',
    'zip' => 'application/zip',
    _ => 'application/octet-stream',
  };
}

/// Retient les pièces admissibles : 25 Mo chacune, 10 au total.
({List<PieceLocale> retenues, List<String> tropLourdes, bool limiteAtteinte}) filtrerPieces(
  List<PieceLocale> existantes,
  List<PieceLocale> nouvelles,
) {
  final tropLourdes = nouvelles.where((p) => (p.taille ?? 0) > maxOctetsPiece).map((p) => p.nom).toList();
  final admises = nouvelles.where((p) => (p.taille ?? 0) <= maxOctetsPiece).toList();
  final restant = maxPieces - existantes.length;
  final retenues = admises.take(restant < 0 ? 0 : restant).toList();
  return (retenues: retenues, tropLourdes: tropLourdes, limiteAtteinte: retenues.length < admises.length);
}

/// Pièces jointes d'une décision : photo prise sur le chantier, image de la
/// galerie ou document (PDF, Excel…).
class ChoixPieces extends StatelessWidget {
  const ChoixPieces({required this.pieces, required this.onChange, this.desactive = false, super.key});

  final List<PieceLocale> pieces;
  final ValueChanged<List<PieceLocale>> onChange;
  final bool desactive;

  Future<void> _ajouter(BuildContext context, List<PieceLocale> nouvelles) async {
    final r = filtrerPieces(pieces, nouvelles);
    if (r.tropLourdes.isNotEmpty) {
      await informer(context, 'Fichier trop volumineux', '${r.tropLourdes.join(', ')} : 25 Mo maximum par fichier.');
    } else if (r.limiteAtteinte && context.mounted) {
      await informer(context, 'Pièces jointes', '$maxPieces fichiers maximum.');
    }
    if (r.retenues.isNotEmpty) onChange([...pieces, ...r.retenues]);
  }

  Future<List<PieceLocale>> _depuisImages(List<XFile> images) async => [
    for (final (i, x) in images.indexed)
      PieceLocale(
        chemin: x.path,
        nom: x.name.isNotEmpty ? x.name : 'photo-${DateTime.now().millisecondsSinceEpoch}-${i + 1}.jpg',
        type: x.mimeType ?? typeMimeDepuisNom(x.name.isNotEmpty ? x.name : 'photo.jpg'),
        taille: await x.length(),
      ),
  ];

  Future<void> _photo(BuildContext context) async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70);
      if (x == null) return;
      final locales = await _depuisImages([x]);
      if (context.mounted) await _ajouter(context, locales);
    } catch (_) {
      if (context.mounted) {
        await informer(
          context,
          'Appareil photo',
          "Autorisez l'appareil photo pour DG Flow RC dans les réglages du téléphone.",
        );
      }
    }
  }

  Future<void> _galerie(BuildContext context) async {
    try {
      final images = await ImagePicker().pickMultiImage(imageQuality: 70, limit: maxPieces - pieces.length);
      if (images.isEmpty || !context.mounted) return;
      final locales = await _depuisImages(images);
      if (context.mounted) await _ajouter(context, locales);
    } catch (_) {
      if (context.mounted) await informer(context, 'Galerie', 'Impossible d’ouvrir la galerie de photos.');
    }
  }

  Future<void> _document(BuildContext context) async {
    try {
      final fichiers = await FilePicker.pickFiles();
      if (fichiers.isEmpty || !context.mounted) return;
      final locales = <PieceLocale>[];
      for (final f in fichiers) {
        final chemin = f.path;
        if (chemin == null) continue;
        locales.add(
          PieceLocale(chemin: chemin, nom: f.name, type: typeMimeDepuisNom(f.name), taille: await f.length()),
        );
      }
      if (context.mounted) await _ajouter(context, locales);
    } catch (_) {
      if (context.mounted) await informer(context, 'Document', 'Impossible de choisir un document.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final restant = maxPieces - pieces.length;
    final boutons = [
      if (!kIsWeb) (Icons.photo_camera_outlined, 'Photo', _photo),
      (Icons.photo_library_outlined, 'Galerie', _galerie),
      (Icons.description_outlined, 'Document', _document),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Pièces jointes', style: Typo.libelle.copyWith(color: p.texte)),
        Text(
          'Facultatif. Photo, image ou document, 25 Mo maximum chacun (${pieces.length}/$maxPieces).',
          style: Typo.secondaire.copyWith(color: p.texteSecondaire),
        ),
        const SizedBox(height: Espace.s),
        Row(
          children: [
            for (final (i, (icone, libelle, action)) in boutons.indexed) ...[
              if (i > 0) const SizedBox(width: Espace.s),
              Expanded(
                child: _BoutonPiece(
                  icone: icone,
                  libelle: libelle,
                  onTap: desactive || restant <= 0 ? null : () => action(context),
                ),
              ),
            ],
          ],
        ),
        for (final (i, piece) in pieces.indexed)
          Padding(
            padding: const EdgeInsets.only(top: Espace.s),
            child: Container(
              padding: const EdgeInsets.only(left: Espace.m),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(Rayon.s + 2),
                border: Border.all(color: p.bordure),
              ),
              child: Row(
                children: [
                  Icon(iconeFichier(piece.type), size: 20, color: p.texteSecondaire),
                  const SizedBox(width: Espace.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          piece.nom,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Typo.corps.copyWith(color: p.texte),
                        ),
                        if (piece.taille != null)
                          Text(Format.taille(piece.taille!), style: Typo.petit.copyWith(color: p.texteSecondaire)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Retirer ${piece.nom}',
                    onPressed: desactive ? null : () => onChange([...pieces]..removeAt(i)),
                    icon: Icon(Icons.cancel_rounded, color: p.texteTertiaire),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _BoutonPiece extends StatelessWidget {
  const _BoutonPiece({required this.icone, required this.libelle, required this.onTap});

  final IconData icone;
  final String libelle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: Semantics(
        button: true,
        label: 'Joindre : $libelle',
        excludeSemantics: true,
        child: Material(
          color: p.accentClair,
          borderRadius: BorderRadius.circular(Rayon.m),
          child: InkWell(
            borderRadius: BorderRadius.circular(Rayon.m),
            onTap: onTap,
            child: CustomPaint(
              painter: _Pointilles(couleur: p.action.withValues(alpha: 0.6)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Espace.m),
                child: Column(
                  children: [
                    Icon(icone, color: p.action),
                    const SizedBox(height: 4),
                    Text(libelle, style: Typo.libelle.copyWith(fontSize: 14, color: p.action)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bordure pointillée (zone d'ajout).
class _Pointilles extends CustomPainter {
  const _Pointilles({required this.couleur});

  final Color couleur;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(Rayon.m)).deflate(0.5);
    final chemin = Path()..addRRect(rect);
    final peinture = Paint()
      ..color = couleur
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final m in chemin.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 5), peinture);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_Pointilles old) => old.couleur != couleur;
}
