/// Règles du circuit RC reprises de DG Flow (rc-status.ts, regles.ts,
/// statuts.ts, parcours.ts) pour l'API de démonstration. Les clés d'étape
/// sont celles du CODE : DP, DE (= Directeur d'Exploitation), RE (= Directeur
/// d'Études), SG ; RP pour le Responsable de Projet.
library;

const Map<String, String> libellesStatut = {
  'draft': 'Brouillon',
  'approved_by_responsable_projet': 'Approuvé par RP',
  'approved_by_directeur_projet': 'Approuvé par DP',
  'rejected_by_directeur_projet': 'Rejeté par DP',
  'approved_by_directeur_exploitation': 'Approuvé par DEX',
  'rejected_by_directeur_exploitation': 'Rejeté par DEX',
  'approved_by_responsable_etude': 'Approuvé par DE',
  'rejected_by_responsable_etude': 'Rejeté par DE',
  'approved_by_service_gestion': 'Approuvé par SG',
  'rejected_by_service_gestion_to_directeur_exploitation': 'Rejeté par SG → DEX',
  'rejected_by_service_gestion_to_directeur_projet': 'Rejeté par SG → DP',
  'rejected_by_service_gestion_to_responsable_projet': 'Rejeté par SG → RP',
  'rejected_by_service_gestion_to_responsable_etude': 'Rejeté par SG → DE',
  'rejected_by_responsable_etude_to_directeur_exploitation': 'Rejeté par DE → DEX',
  'rejected_by_responsable_etude_to_directeur_projet': 'Rejeté par DE → DP',
  'rejected_by_responsable_etude_to_responsable_projet': 'Rejeté par DE → RP',
};

/// `presentationStatut` (statuts.ts).
({String libelle, String ton}) presentationStatut(String statut) {
  final libelle = libellesStatut[statut] ?? statut;
  var ton = 'info';
  if (statut == 'draft') {
    ton = 'neutre';
  } else if (statut == 'approved_by_service_gestion') {
    ton = 'succes';
  } else if (statut.startsWith('rejected_') && statut.contains('_to_')) {
    ton = 'alerte';
  } else if (statut.startsWith('rejected_')) {
    ton = 'danger';
  }
  return (libelle: libelle, ton: ton);
}

/// Statuts sur lesquels chaque étape décide (regles.ts : STATUTS_DECISION).
const Map<String, List<String>> statutsDecision = {
  'DP': [
    'approved_by_responsable_projet',
    'rejected_by_directeur_exploitation',
    'rejected_by_service_gestion_to_directeur_projet',
    'rejected_by_responsable_etude_to_directeur_projet',
  ],
  'DE': [
    'approved_by_directeur_projet',
    'rejected_by_service_gestion_to_directeur_exploitation',
    'rejected_by_responsable_etude_to_directeur_exploitation',
  ],
  'RE': ['approved_by_directeur_exploitation', 'rejected_by_service_gestion_to_responsable_etude'],
  'SG': ['approved_by_responsable_etude'],
};

const Map<String, List<String>> _bucketsDp = {
  'toReceive': [
    'draft',
    'rejected_by_service_gestion_to_responsable_projet',
    'rejected_by_responsable_etude_to_responsable_projet',
  ],
  'pending': [
    'approved_by_responsable_projet',
    'rejected_by_service_gestion_to_directeur_projet',
    'rejected_by_responsable_etude_to_directeur_projet',
  ],
  'approved': [
    'approved_by_directeur_projet',
    'approved_by_directeur_exploitation',
    'approved_by_responsable_etude',
    'approved_by_service_gestion',
  ],
  'rejected': [
    'rejected_by_directeur_projet',
    'rejected_by_directeur_exploitation',
    'rejected_by_responsable_etude',
    'rejected_by_service_gestion_to_directeur_exploitation',
  ],
};

const Map<String, List<String>> _bucketsDe = {
  'toReceive': [],
  'pending': ['approved_by_directeur_projet'],
  'approved': ['approved_by_directeur_exploitation', 'approved_by_responsable_etude', 'approved_by_service_gestion'],
  'rejected': [
    'rejected_by_directeur_exploitation',
    'rejected_by_responsable_etude',
    'rejected_by_service_gestion_to_directeur_exploitation',
    'rejected_by_responsable_etude_to_directeur_exploitation',
  ],
};

const Map<String, List<String>> _bucketsRe = {
  'toReceive': [],
  'pending': ['approved_by_directeur_exploitation', 'rejected_by_service_gestion_to_responsable_etude'],
  'approved': ['approved_by_responsable_etude', 'approved_by_service_gestion'],
  'rejected': [
    'rejected_by_responsable_etude',
    'rejected_by_responsable_etude_to_directeur_exploitation',
    'rejected_by_responsable_etude_to_directeur_projet',
    'rejected_by_responsable_etude_to_responsable_projet',
  ],
};

const Map<String, List<String>> _bucketsSg = {
  'toReceive': [],
  'pending': ['approved_by_responsable_etude'],
  'approved': ['approved_by_service_gestion'],
  'rejected': [
    'rejected_by_service_gestion_to_directeur_exploitation',
    'rejected_by_service_gestion_to_directeur_projet',
    'rejected_by_service_gestion_to_responsable_projet',
    'rejected_by_service_gestion_to_responsable_etude',
  ],
};

final Map<String, List<String>> _bucketsSuivi = {
  'toReceive': ['draft'],
  'pending': [
    'approved_by_responsable_projet',
    'approved_by_directeur_projet',
    'approved_by_directeur_exploitation',
    'approved_by_responsable_etude',
  ],
  'approved': ['approved_by_service_gestion'],
  'rejected': libellesStatut.keys.where((s) => s.startsWith('rejected')).toList(),
};

String? bucketDuStatut(String? etape, String statut) {
  final table = switch (etape) {
    'DP' => _bucketsDp,
    'DE' => _bucketsDe,
    'RE' => _bucketsRe,
    'SG' => _bucketsSg,
    _ => _bucketsSuivi,
  };
  for (final b in const ['toReceive', 'pending', 'approved', 'rejected']) {
    if (table[b]!.contains(statut)) return b;
  }
  return null;
}

const Map<String, String> libellesBucket = {
  'toReceive': 'À recevoir',
  'pending': 'En attente',
  'approved': 'Validés',
  'rejected': 'Rejetés / renvoyés',
};

/// Libellés du parcours (parcours.ts : LIBELLES).
const Map<String, ({String etape, String etat})> libellesAction = {
  'APPROVED_BY_RESPONSABLE_PROJET': (etape: 'Envoyé pour validation au Directeur Projet', etat: 'completed'),
  'APPROVED_BY_DIRECTEUR_PROJET': (etape: 'Approuvé par le Directeur Projet', etat: 'completed'),
  'REJECTED_BY_DIRECTEUR_PROJET': (etape: 'Rejeté par le Directeur Projet', etat: 'rejected'),
  'APPROVED_BY_DIRECTEUR_EXPLOITATION': (etape: "Approuvé par le Directeur d'Exploitation", etat: 'completed'),
  'REJECTED_BY_DIRECTEUR_EXPLOITATION': (etape: "Rejeté par le Directeur d'Exploitation", etat: 'rejected'),
  'APPROVED_BY_RESPONSABLE_ETUDE': (etape: "Approuvé par le Directeur d'Études", etat: 'completed'),
  'REJECTED_BY_RESPONSABLE_ETUDE': (etape: "Rejeté par le Directeur d'Études", etat: 'rejected'),
  'APPROVED_BY_SERVICE_GESTION': (etape: 'Approuvé par Service Gestion', etat: 'completed'),
  'REJECTED_BY_SERVICE_GESTION_TO_DIRECTEUR_EXPLOITATION': (
    etape: "Rejeté par SG → Directeur d'Exploitation",
    etat: 'rejected',
  ),
  'REJECTED_BY_SERVICE_GESTION_TO_DIRECTEUR_PROJET': (etape: 'Rejeté par SG → Directeur Projet', etat: 'rejected'),
  'REJECTED_BY_SERVICE_GESTION_TO_RESPONSABLE_PROJET': (etape: 'Rejeté par SG → Responsable Projet', etat: 'rejected'),
  'REJECTED_BY_SERVICE_GESTION_TO_RESPONSABLE_ETUDE': (etape: "Rejeté par SG → Directeur d'Études", etat: 'rejected'),
  'REJECTED_BY_RESPONSABLE_ETUDE_TO_DIRECTEUR_EXPLOITATION': (
    etape: "Rejeté par DE → Directeur d'Exploitation",
    etat: 'rejected',
  ),
  'REJECTED_BY_RESPONSABLE_ETUDE_TO_DIRECTEUR_PROJET': (etape: 'Rejeté par DE → Directeur Projet', etat: 'rejected'),
  'REJECTED_BY_RESPONSABLE_ETUDE_TO_RESPONSABLE_PROJET': (
    etape: 'Rejeté par DE → Responsable Projet',
    etat: 'rejected',
  ),
};

const Map<String, String> enAttente = {
  'approved_by_responsable_projet': 'En attente de validation du Directeur Projet',
  'approved_by_directeur_projet': "En attente de validation du Directeur d'Exploitation",
  'approved_by_directeur_exploitation': "En attente de validation du Directeur d'Études",
  'approved_by_responsable_etude': 'En attente de validation du Service Gestion',
};

String infoRoleKey(String nomRole) {
  if (nomRole.contains('Gestion')) return 'SERVICE_GESTION';
  if (nomRole.contains('Exploitation')) return 'DIRECTEUR_EXPLOITATION';
  if (nomRole.contains('Etude') || nomRole.contains('étude')) return 'RESPONSABLE_ETUDE';
  if (nomRole.contains('Directeur')) return 'DIRECTEUR_PROJET';
  return 'RESPONSABLE_PROJET';
}

String infoRoleLabel(String cle) => switch (cle) {
  'SERVICE_GESTION' => 'Service Gestion',
  'RESPONSABLE_ETUDE' => "Directeur d'Études",
  'DIRECTEUR_EXPLOITATION' => "Directeur d'Exploitation",
  'DIRECTEUR_PROJET' => 'Directeur Projet',
  _ => 'Responsable Projet',
};

({String etape, String etat})? libelleAction(String action) {
  final l = libellesAction[action];
  if (l != null) return l;
  final m = RegExp(r'^INFO_(REQUEST|RESPONSE)_BY_(.+)_TO_(.+)$').firstMatch(action);
  if (m != null) {
    final de = infoRoleLabel(m.group(2)!);
    final vers = infoRoleLabel(m.group(3)!);
    return (
      etape: m.group(1) == 'REQUEST'
          ? "Demande d'information : $de → $vers"
          : "Réponse à la demande d'information : $de → $vers",
      etat: 'info',
    );
  }
  if (action == 'NOTE') return (etape: 'Note interne', etat: 'note');
  return null;
}

/// Approbation de l'étape précédente, vue par chaque rôle (predecessorApproveActions).
List<String> actionsPredecesseur(String nomRole) => switch (nomRole) {
  'Directeurs Projet' => ['APPROVED_BY_RESPONSABLE_PROJET'],
  "Directeurs d'Exploitation" => ['APPROVED_BY_DIRECTEUR_PROJET'],
  'Responsable Etude RC' => ['APPROVED_BY_DIRECTEUR_EXPLOITATION'],
  'Service Gestion' ||
  'Agent Service Gestion' => ['APPROVED_BY_RESPONSABLE_ETUDE', 'APPROVED_BY_DIRECTEUR_EXPLOITATION'],
  _ => const [],
};

String? auteurRejet(String statut) {
  if (statut.startsWith('rejected_by_directeur_projet')) return 'DP';
  if (statut.startsWith('rejected_by_directeur_exploitation')) return 'DEX';
  if (statut.startsWith('rejected_by_responsable_etude')) return 'DE';
  if (statut.startsWith('rejected_by_service_gestion')) return 'SG';
  return null;
}

/// Messages de la garde de consultation (rc-consultation.ts).
String messageGardeConsultation({required bool avenant, required bool perimee, String action = 'approuver'}) {
  final doc = avenant ? "l'avenant" : 'le RC';
  final verbe = action == 'rejeter' ? 'de rejeter' : "d'approuver";
  final majuscule = '${doc[0].toUpperCase()}${doc.substring(1)}';
  return perimee
      ? '$majuscule a été modifié depuis votre dernière consultation : rouvrez-le avant $verbe.'
      : 'Consultez $doc avant $verbe.';
}

String messageGardeTableau({required bool avenant, String action = 'approuver'}) {
  final verbe = action == 'rejeter' ? 'de rejeter' : "d'approuver";
  return 'Consultez ${avenant ? 'le tableau explicatif' : 'le tableau comparatif'} avant $verbe.';
}

const Map<String, String> messagesStatut = {
  'approved_by_directeur_projet': "Approuvé — transmis au Directeur d'Exploitation",
  'approved_by_directeur_exploitation': "Approuvé — transmis au Directeur d'Études",
  'approved_by_responsable_etude': 'Approuvé — transmis au Service Gestion',
  'approved_by_service_gestion': 'Approuvé — circuit de validation terminé',
  'rejected_by_directeur_projet': 'Rejeté — renvoyé au Responsable de Projet',
  'rejected_by_directeur_exploitation': 'Rejeté — renvoyé au Directeur Projet',
};
