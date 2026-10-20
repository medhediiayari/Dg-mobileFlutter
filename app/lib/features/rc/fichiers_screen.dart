import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
      appBar: AppBar(title: const Text('Fichiers'), flexibleSpace: const DegradeEnTete()),
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
                      icone: LucideIcons.folderOpen,
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
    final parDossier = <String, List<FichierDossier>>{};
    for (final f in fichiers) {
      parDossier.putIfAbsent(f.dossier == null || f.dossier!.isEmpty ? '' : f.dossier!, () => []).add(f);
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(Espace.l, Espace.l, Espace.l, Espace.xl + MediaQuery.paddingOf(context).bottom),
      children: [
        // Un dossier = une section du web (titre marine, icône Folder `text-[#0061A7]`).
        for (final MapEntry(key: dossier, value: liste) in parDossier.entries)
          Section(
            titre: dossier.isEmpty ? 'Dossier principal' : dossier,
            icone: LucideIcons.folder,
            droite: Compteur(valeur: liste.length),
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, f) in liste.indexed) _ligne(context, f, derniere: i == liste.length - 1),
              ],
            ),
          ),
      ],
    );
  }

  Widget _ligne(BuildContext context, FichierDossier f, {required bool derniere}) {
    final p = context.dg;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: _enCours == null ? () => _ouvrir(f) : null,
        child: Semantics(
          button: true,
          label: 'Ouvrir ${f.nom}',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.all(Espace.m),
            decoration: BoxDecoration(
              border: derniere ? null : Border(bottom: BorderSide(color: p.bordure)),
            ),
            child: Row(
              children: [
                // Tuile d'icône `w-10 h-10 rounded-lg bg-blue-50`, icône `text-[#0061A7]`.
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: p.accentClair,
                    borderRadius: BorderRadius.circular(Rayon.m),
                  ),
                  child: Icon(iconeFichier(f.type), size: 20, color: p.action),
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
                        style: Typo.libelle.copyWith(color: p.texte),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${Format.taille(f.taille)}, déposé le ${Format.date(f.deposeLe)}${f.deposePar != null ? ' par ${f.deposePar}' : ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Typo.petit.copyWith(color: p.texteTertiaire, fontWeight: FontWeight.w400, fontSize: 12.5),
                      ),
                      if (f.categorie != null) ...[
                        const SizedBox(height: 5),
                        _Categorie(nom: f.categorie!.nom, couleur: _couleurWeb(f.categorie!.couleur) ?? p.neutre),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: Espace.s),
                if (_enCours == f.id)
                  SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, value: _progression),
                  )
                else
                  Icon(LucideIcons.eye, size: 18, color: p.texteDiscret),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Catégorie de fichier : pastille `rounded-md border` dans la couleur choisie sur le web.
class _Categorie extends StatelessWidget {
  const _Categorie({required this.nom, required this.couleur});

  final String nom;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    final sombre = context.sombre;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: sombre ? 0.24 : 0.1),
        border: Border.all(color: couleur.withValues(alpha: sombre ? 0.5 : 0.35)),
        borderRadius: BorderRadius.circular(Rayon.s),
      ),
      child: Text(
        nom,
        style: Typo.sigle.copyWith(fontSize: 11, color: sombre ? Color.lerp(couleur, Colors.white, 0.55) : couleur),
      ),
    );
  }
}
