/// Position d'un document dans le circuit RP → DP → DEX → DE → SG, lue depuis
/// son statut (même table que STATUS_ACTIVE_GROUP, dgflow/lib/rc-status.ts) :
/// l'étape « en cours » est celle qui doit agir maintenant.
library;

class EtapeCircuit {
  const EtapeCircuit(this.sigle, this.libelle);

  final String sigle;
  final String libelle;
}

const List<EtapeCircuit> etapesCircuit = [
  EtapeCircuit('RP', 'Responsable de projet'),
  EtapeCircuit('DP', 'Directeur projet'),
  EtapeCircuit('DEX', "Directeur d'exploitation"),
  EtapeCircuit('DE', "Directeur d'études"),
  EtapeCircuit('SG', 'Service gestion'),
];

enum ModeParcours { brouillon, attente, renvoi, termine }

class PositionParcours {
  const PositionParcours({required this.index, required this.mode, required this.phrase, this.origine});

  /// Étape qui doit agir (0 = RP … 4 = SG) ; 5 quand le circuit est terminé.
  final int index;
  final ModeParcours mode;

  /// Étape qui a renvoyé le document (mode renvoi).
  final int? origine;

  /// « Chez le directeur d'exploitation », « Renvoyé au directeur projet par le SG »…
  final String phrase;
}

const Map<String, (int, int)> _renvois = {
  'rejected_by_directeur_projet': (0, 1),
  'rejected_by_directeur_exploitation': (1, 2),
  'rejected_by_responsable_etude': (2, 3),
  'rejected_by_service_gestion_to_responsable_projet': (0, 4),
  'rejected_by_service_gestion_to_directeur_projet': (1, 4),
  'rejected_by_service_gestion_to_directeur_exploitation': (2, 4),
  'rejected_by_service_gestion_to_responsable_etude': (3, 4),
  'rejected_by_responsable_etude_to_responsable_projet': (0, 3),
  'rejected_by_responsable_etude_to_directeur_projet': (1, 3),
  'rejected_by_responsable_etude_to_directeur_exploitation': (2, 3),
};

const Map<String, int> _avances = {
  'approved_by_responsable_projet': 1,
  'approved_by_directeur_projet': 2,
  'approved_by_directeur_exploitation': 3,
  'approved_by_responsable_etude': 4,
};

String _article(int i) => 'au ${etapesCircuit[i].libelle.toLowerCase()}';

PositionParcours positionParcours(String statut) {
  if (statut == 'approved_by_service_gestion') {
    return const PositionParcours(index: 5, mode: ModeParcours.termine, phrase: 'Validé par le service gestion');
  }
  final renvoi = _renvois[statut];
  if (renvoi != null) {
    final (cible, origine) = renvoi;
    return PositionParcours(
      index: cible,
      mode: ModeParcours.renvoi,
      origine: origine,
      phrase: 'Renvoyé ${_article(cible)} par le ${etapesCircuit[origine].sigle}',
    );
  }
  final avance = _avances[statut];
  if (avance != null) {
    return PositionParcours(
      index: avance,
      mode: ModeParcours.attente,
      phrase: 'Chez le ${etapesCircuit[avance].libelle.toLowerCase()}',
    );
  }
  return const PositionParcours(
    index: 0,
    mode: ModeParcours.brouillon,
    phrase: 'Brouillon, chez le responsable de projet',
  );
}
