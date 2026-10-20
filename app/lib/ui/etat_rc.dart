import 'package:flutter/material.dart';

import '../core/utils/parcours.dart';
import 'theme.dart';

/// Habillage d'un RC selon son état, commun à la carte de liste et à l'en-tête
/// de la fiche — celui des cartes des écrans de validation du web
/// (`RcValidation*.tsx`) : liseré `border-l-4`, en-tête teinté `from-*-50`,
/// tuile d'icône en dégradé.
///
/// - information demandée, ou renvoi « Correction requise » d'un SG / DE
///   (`rejected_*_to_*`) à reprendre : ambre ;
/// - rejeté / renvoyé : rouge ;
/// - validé par le service gestion : émeraude ;
/// - à décider : `#0061A7` (avenant : teal) ;
/// - ailleurs dans le circuit : sans liseré ([lisere] nul).
({Color? lisere, Teinte teinte, List<Color> degrade}) habillageEtatRc(
  Palette p, {
  required String statut,
  required bool avenant,
  required bool decideur,
  required bool infoPourMoi,
}) {
  final pos = positionParcours(statut);
  final ambre = (lisere: p.ambre.plein, teinte: p.ambre, degrade: [p.ambre.plein, p.ambre.vif]);
  if (infoPourMoi) return ambre;
  if (pos.mode == ModeParcours.renvoi) {
    if (decideur && statut.contains('_to_')) return ambre;
    return (lisere: p.rouge.plein, teinte: p.rouge, degrade: [p.rouge.vif, p.rouge.fonce]);
  }
  if (pos.mode == ModeParcours.termine) {
    return (lisere: p.emeraude.plein, teinte: p.emeraude, degrade: [p.emeraude.vif, p.vert.vif]);
  }
  final type = avenant
      ? (teinte: p.teal, degrade: [p.teal.vif, p.teal.fonce], lisere: p.teal.plein)
      : (teinte: p.bleu, degrade: [p.action, p.bleu.vif], lisere: p.action);
  if (decideur) return (lisere: type.lisere, teinte: type.teinte, degrade: type.degrade);
  return (lisere: null, teinte: p.gris, degrade: type.degrade);
}
