import 'commun.dart';
import 'json.dart';

enum EtatEtape {
  completed,
  rejected,
  info,
  note,
  current;

  static EtatEtape depuis(Object? v) => EtatEtape.values.firstWhere((e) => e.name == v, orElse: () => EtatEtape.note);
}

/// Une ligne de la frise du parcours (`GET /rc/:rcId/parcours`).
class EtapeParcours {
  const EtapeParcours({
    required this.etape,
    required this.etat,
    required this.automatique,
    required this.pieces,
    this.id,
    this.le,
    this.par,
    this.motif,
    this.message,
    this.vers,
  });

  factory EtapeParcours.fromJson(Json j) => EtapeParcours(
    id: asIntOrNull(j['id']),
    etape: asString(j['etape']),
    etat: EtatEtape.depuis(j['etat']),
    le: asDateOrNull(j['le']),
    par: asStringOrNull(j['par']),
    motif: asStringOrNull(j['motif']),
    message: asStringOrNull(j['message']),
    vers: asStringOrNull(j['vers']),
    automatique: asBool(j['automatique']),
    pieces: asList(j['pieces'], PieceJointe.fromJson),
  );

  final int? id;
  final String etape;
  final EtatEtape etat;
  final DateTime? le;
  final String? par;
  final String? motif;
  final String? message;
  final String? vers;
  final bool automatique;
  final List<PieceJointe> pieces;
}

class Parcours {
  const Parcours({required this.statut, required this.etapes});

  factory Parcours.fromJson(Json j) =>
      Parcours(statut: asString(j['statut'], 'draft'), etapes: asList(j['etapes'], EtapeParcours.fromJson));

  final String statut;
  final List<EtapeParcours> etapes;
}
