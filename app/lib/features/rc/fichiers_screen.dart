import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/models.dart';
import '../../core/utils/format.dart';
import '../../ui/telechargement.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/composants.dart';
import '../../ui/widgets/liste_pieces.dart';
import '../../ui/widgets/squelette.dart';
import 'rc_providers.dart';

Color? _couleurWeb(String hex) {
  final h = hex.replaceAll('#', '');
  if (h.length != 6) return null;
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(0xFF000000 | v);
}

/// Dossier « Fichiers » d'un RC / avenant, en consultation — le contenu de la
/// fenêtre « Fichiers (n) » des cartes de validation web. Pas d'ajout ni de
/// suppression depuis le mobile.
class FichiersScreen extends ConsumerStatefulWidget {
  const FichiersScreen({required this.rcId, super.key});

  final int rcId;

  @override
  ConsumerState<FichiersScreen> createState() => _FichiersScreenState();
}

class _FichiersScreenState extends ConsumerState<FichiersScreen> {
  int? _enCours;
  double? _progression;

  Future<void> _ouvrir(FichierDossier f) async {
    setState(() {
      _enCours = f.id;
      _progression = null;
    });
    await telechargerEtOuvrir(
      context,
      ref,
      chemin: '/rc/${widget.rcId}/pieces/${f.id}',
      nom: f.nom,
      type: f.type,
      progression: (v) {
        if (mounted) setState(() => _progression = v);
      },
    );
    if (mounted) setState(() => _enCours = null);
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(fichiersProvider(widget.rcId));
    return Scaffold(
      appBar: AppBar(title: const Text('Fichiers')),
      body: switch (etat) {
        AsyncValue(:final value?) => RefreshIndicator(
          onRefresh: () async {
            try {
              ref.invalidate(fichiersProvider(widget.rcId));
              await ref.read(fichiersProvider(widget.rcId).future);
            } catch (_) {}
          },
          child: value.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    EtatVide(
                      icone: Icons.folder_open_outlined,
                      titre: 'Aucun fichier',
                      texte: 'Le dossier de ce document est vide.',
                    ),
                  ],
                )
              : _liste(context, value),
        ),
        AsyncValue(:final error?) => EtatErreur(
          message: messageErreur(error),
          onReessayer: () => ref.invalidate(fichiersProvider(widget.rcId)),
        ),
        _ => const SingleChildScrollView(child: ListeSquelette(nombre: 4)),
      },
    );
  }

  Widget _liste(BuildContext context, List<FichierDossier> fichiers) {
    final p = context.dg;
    final parDossier = <String, List<FichierDossier>>{};
    for (final f in fichiers) {
      parDossier.putIfAbsent(f.dossier == null || f.dossier!.isEmpty ? '' : f.dossier!, () => []).add(f);
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(Espace.l, Espace.s, Espace.l, Espace.xxl + MediaQuery.paddingOf(context).bottom),
      children: [
        for (final MapEntry(key: dossier, value: liste) in parDossier.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: Espace.m, bottom: Espace.s, left: 2),
            child: Row(
              children: [
                Icon(Icons.folder_outlined, size: 18, color: p.texteSecondaire),
                const SizedBox(width: Espace.s),
                Expanded(
                  child: Text(
                    dossier.isEmpty ? 'Dossier principal' : dossier,
                    style: Typo.libelle.copyWith(color: p.texte),
                  ),
                ),
                Text('${liste.length}', style: Typo.montant.copyWith(fontSize: 14, color: p.texteTertiaire)),
              ],
            ),
          ),
          for (final f in liste)
            Padding(
              padding: const EdgeInsets.only(bottom: Espace.s),
              child: Material(
                color: p.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Rayon.m + 2),
                  side: BorderSide(color: p.bordure),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _enCours == null ? () => _ouvrir(f) : null,
                  child: Semantics(
                    button: true,
                    label: 'Ouvrir ${f.nom}',
                    excludeSemantics: true,
                    child: Padding(
                      padding: const EdgeInsets.all(Espace.m),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: p.accentClair,
                              borderRadius: BorderRadius.circular(Rayon.m),
                            ),
                            child: Icon(iconeFichier(f.type), color: p.action),
                          ),
                          const SizedBox(width: Espace.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.nom,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Typo.corpsFort.copyWith(color: p.texte),
                                ),
                                Text(
                                  '${Format.taille(f.taille)}, déposé le ${Format.date(f.deposeLe)}${f.deposePar != null ? ' par ${f.deposePar}' : ''}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Typo.secondaire.copyWith(color: p.texteSecondaire),
                                ),
                                if (f.categorie != null) ...[
                                  const SizedBox(height: 4),
                                  Builder(
                                    builder: (context) {
                                      final c = _couleurWeb(f.categorie!.couleur) ?? p.neutre;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: c.withValues(alpha: context.sombre ? 0.28 : 0.13),
                                          borderRadius: BorderRadius.circular(Rayon.s),
                                        ),
                                        child: Text(
                                          f.categorie!.nom,
                                          style: Typo.petit.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: context.sombre ? Color.lerp(c, Colors.white, 0.55) : c,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: Espace.s),
                          if (_enCours == f.id)
                            SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4, value: _progression),
                            )
                          else
                            Icon(Icons.open_in_new_rounded, size: 19, color: p.texteTertiaire),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
