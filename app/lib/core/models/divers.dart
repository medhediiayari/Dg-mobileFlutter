import 'commun.dart';
import 'json.dart';

/// Réponse d'une décision (approuver, rejeter, demande / réponse d'information, BC).
class ResultatDecision {
  const ResultatDecision({
    required this.succes,
    required this.message,
    required this.statut,
    this.evenementId,
    this.autoValidation,
    this.estBc,
  });

  factory ResultatDecision.fromJson(Json j) => ResultatDecision(
    succes: asBool(j['succes'], true),
    message: asString(j['message'], 'Décision enregistrée'),
    statut: asString(j['statut']),
    evenementId: asIntOrNull(j['evenementId']),
    autoValidation: asStringOrNull(j['autoValidation']),
    estBc: j['estBc'] == null ? null : asBool(j['estBc']),
  );

  final bool succes;
  final String message;
  final String statut;

  /// Événement créé par la décision : les pièces jointes s'y rattachent.
  final int? evenementId;
  final String? autoValidation;
  final bool? estBc;
}

class CategorieFichier {
  const CategorieFichier({required this.nom, required this.couleur});

  final String nom;

  /// Couleur web (#RRGGBB).
  final String couleur;
}

/// Fichier du dossier « Fichiers » d'un RC (consultation).
class FichierDossier {
  const FichierDossier({
    required this.id,
    required this.nom,
    required this.taille,
    required this.type,
    required this.deposeLe,
    this.dossier,
    this.description,
    this.categorie,
    this.deposePar,
  });

  factory FichierDossier.fromJson(Json j) {
    final c = asJsonOrNull(j['categorie']);
    return FichierDossier(
      id: asInt(j['id']),
      nom: asString(j['nom'], 'fichier'),
      taille: asInt(j['taille']),
      type: asString(j['type'], 'application/octet-stream'),
      deposeLe: asDate(j['deposeLe']),
      dossier: asStringOrNull(j['dossier']),
      description: asStringOrNull(j['description']),
      categorie: c == null ? null : CategorieFichier(nom: asString(c['nom']), couleur: asString(c['couleur'])),
      deposePar: asStringOrNull(j['deposePar']),
    );
  }

  final int id;
  final String nom;
  final int taille;
  final String type;
  final DateTime deposeLe;
  final String? dossier;
  final String? description;
  final CategorieFichier? categorie;
  final String? deposePar;
}

/// Notification RC de DG Flow (mêmes lignes que la cloche du web).
class NotificationRc {
  const NotificationRc({
    required this.id,
    required this.type,
    required this.titre,
    required this.message,
    required this.lue,
    required this.le,
    this.rcId,
    this.projetId,
    this.acteur,
  });

  factory NotificationRc.fromJson(Json j) => NotificationRc(
    id: asInt(j['id']),
    type: asString(j['type']),
    titre: asString(j['titre']),
    message: asString(j['message']),
    lue: asBool(j['lue']),
    le: asDate(j['le']),
    rcId: asIntOrNull(j['rcId']),
    projetId: asIntOrNull(j['projetId']),
    acteur: asStringOrNull(j['acteur']),
  );

  final int id;
  final String type;
  final String titre;
  final String message;
  final bool lue;
  final DateTime le;
  final int? rcId;
  final int? projetId;
  final String? acteur;

  NotificationRc marqueeLue() => NotificationRc(
    id: id,
    type: type,
    titre: titre,
    message: message,
    lue: true,
    le: le,
    rcId: rcId,
    projetId: projetId,
    acteur: acteur,
  );
}

class PageNotifications {
  const PageNotifications({required this.elements, this.suivant});

  factory PageNotifications.fromJson(Json j) =>
      PageNotifications(elements: asList(j['elements'], NotificationRc.fromJson), suivant: asIntOrNull(j['suivant']));

  final List<NotificationRc> elements;

  /// Curseur `avant` de la page suivante, null en fin de liste.
  final int? suivant;
}

/// Réponse de l'envoi des pièces jointes d'une décision.
class ResultatPieces {
  const ResultatPieces({required this.message, required this.pieces});

  factory ResultatPieces.fromJson(Json j) =>
      ResultatPieces(message: asString(j['message']), pieces: asList(j['pieces'], PieceJointe.fromJson));

  final String message;
  final List<PieceJointe> pieces;
}
