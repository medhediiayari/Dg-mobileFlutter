import 'json.dart';

/// Ton d'une pastille de statut, fourni par l'API (`presentationStatut`).
enum Ton {
  neutre,
  info,
  succes,
  alerte,
  danger;

  static Ton depuis(Object? v) => Ton.values.firstWhere((t) => t.name == v, orElse: () => Ton.neutre);
}

/// RC ou avenant.
enum TypeDocument {
  rc('RC'),
  avenant('AVENANT');

  const TypeDocument(this.code);
  final String code;

  static TypeDocument depuis(Object? v) => v == 'AVENANT' ? TypeDocument.avenant : TypeDocument.rc;
}

/// Regroupements du tableau de bord (rc-status.ts : RcWorkflowBucket).
enum Bucket {
  toReceive,
  pending,
  approved,
  rejected;

  static Bucket? depuis(Object? v) {
    for (final b in Bucket.values) {
      if (b.name == v) return b;
    }
    return null;
  }

  /// Libellé de repli si l'API n'en fournit pas.
  String get libelleParDefaut => switch (this) {
    Bucket.toReceive => 'À recevoir',
    Bucket.pending => 'En attente',
    Bucket.approved => 'Validés',
    Bucket.rejected => 'Rejetés / renvoyés',
  };
}

/// Pièce jointe d'une décision (approbation, rejet, demande / réponse d'information).
class PieceJointe {
  const PieceJointe({
    required this.id,
    required this.nom,
    required this.taille,
    required this.type,
    required this.deposeLe,
    required this.categorie,
  });

  factory PieceJointe.fromJson(Json j) => PieceJointe(
    id: asInt(j['id']),
    nom: asString(j['nom'], 'fichier'),
    taille: asInt(j['taille']),
    type: asString(j['type'], 'application/octet-stream'),
    deposeLe: asDate(j['deposeLe']),
    categorie: asString(j['categorie']),
  );

  final int id;
  final String nom;
  final int taille;
  final String type;
  final DateTime deposeLe;
  final String categorie;
}

/// Destinataire possible d'un renvoi ou d'une demande d'information.
class Destinataire {
  const Destinataire({required this.id, required this.nom, required this.role});

  factory Destinataire.fromJson(Json j) =>
      Destinataire(id: asInt(j['id']), nom: asString(j['nom']), role: asString(j['role']));

  final int id;
  final String nom;
  final String role;
}

/// Fichier choisi sur le téléphone, pas encore envoyé.
class PieceLocale {
  const PieceLocale({required this.chemin, required this.nom, required this.type, this.taille});

  final String chemin;
  final String nom;
  final String type;
  final int? taille;
}
