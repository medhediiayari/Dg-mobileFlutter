import 'package:flutter/material.dart';

import '../../core/models/parcours.dart';
import '../../core/utils/format.dart';
import '../theme.dart';
import 'liste_pieces.dart';

/// Frise du parcours : création → étapes de validation → étape en attente.
class FriseParcours extends StatelessWidget {
  const FriseParcours({required this.rcId, required this.etapes, super.key});

  final int rcId;
  final List<EtapeParcours> etapes;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    ({IconData icone, Color couleur, Color fond}) style(EtatEtape e) => switch (e) {
      EtatEtape.completed => (icone: Icons.check_rounded, couleur: p.succes, fond: p.succesFond),
      EtatEtape.rejected => (icone: Icons.undo_rounded, couleur: p.danger, fond: p.dangerFond),
      EtatEtape.info => (icone: Icons.forum_rounded, couleur: p.info, fond: p.infoFond),
      EtatEtape.note => (icone: Icons.sticky_note_2_outlined, couleur: p.neutre, fond: p.neutreFond),
      EtatEtape.current => (icone: Icons.schedule_rounded, couleur: p.alerte, fond: p.alerteFond),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < etapes.length; i++)
          _Etape(etape: etapes[i], style: style(etapes[i].etat), derniere: i == etapes.length - 1, rcId: rcId),
      ],
    );
  }
}

class _Etape extends StatelessWidget {
  const _Etape({required this.etape, required this.style, required this.derniere, required this.rcId});

  final EtapeParcours etape;
  final ({IconData icone, Color couleur, Color fond}) style;
  final bool derniere;
  final int rcId;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final e = etape;
    final sousTitre = [e.par, if (e.le != null) Format.dateHeure(e.le)].whereType<String>().join(', ');
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: style.fond,
                    shape: BoxShape.circle,
                    border: Border.all(color: style.couleur, width: 1.5),
                  ),
                  child: Icon(style.icone, size: 14, color: style.couleur),
                ),
                if (!derniere)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(color: p.bordure, borderRadius: BorderRadius.circular(1)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Espace.s + 2),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: derniere ? 0 : Espace.l + 2, top: 2),
              child: Semantics(
                container: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.etape,
                      style: Typo.corpsFort.copyWith(
                        color: e.etat == EtatEtape.current ? style.couleur : p.texte,
                        height: 1.3,
                      ),
                    ),
                    if (sousTitre.isNotEmpty)
                      Text(sousTitre, style: Typo.secondaire.copyWith(color: p.texteSecondaire)),
                    if (e.vers != null && e.etat != EtatEtape.completed)
                      Text('Adressé à ${e.vers}', style: Typo.secondaire.copyWith(color: p.texteSecondaire)),
                    if (e.motif != null && e.motif!.isNotEmpty)
                      _Bulle(texte: e.motif!, fond: p.dangerFond, couleur: p.danger),
                    if (e.message != null && e.message!.isNotEmpty)
                      _Bulle(
                        texte: e.automatique ? e.message! : '« ${e.message} »',
                        fond: e.automatique ? p.neutreFond : style.fond,
                        couleur: p.texte,
                      ),
                    ListePieces(rcId: rcId, pieces: e.pieces),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bulle extends StatelessWidget {
  const _Bulle({required this.texte, required this.fond, required this.couleur});

  final String texte;
  final Color fond;
  final Color couleur;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: Espace.s),
    padding: const EdgeInsets.symmetric(horizontal: Espace.m, vertical: Espace.s + 1),
    decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(Rayon.m)),
    child: Text(texte, style: Typo.corps.copyWith(fontSize: 15, color: couleur)),
  );
}
