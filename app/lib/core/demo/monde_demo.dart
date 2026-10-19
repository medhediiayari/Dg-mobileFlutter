import '../models/json.dart';

/// Données de démonstration : trois chantiers, dix documents, une équipe.
///
/// Le JSON produit par `ApiDemo` à partir de ce monde a EXACTEMENT la forme du
/// contrat de l'API (backend `modules/rc/lecture.ts`, `parcours.ts`…). Les dates
/// sont relatives à [MondeDemo.t0] pour que « il y a 2 h » reste vrai.

class PersonneDemo {
  const PersonneDemo(this.id, this.prenom, this.nom, this.role);

  final int id;
  final String prenom;
  final String nom;

  /// Nom exact du rôle en base (« Directeurs Projet »…).
  final String role;

  String get nomComplet => '$prenom $nom';
}

const PersonneDemo moiDemo = PersonneDemo(7, 'Camille', 'Lefèvre', 'Directeurs Projet');
const PersonneDemo julien = PersonneDemo(21, 'Julien', 'Marchand', 'Responsables de Projet');
const PersonneDemo thomas = PersonneDemo(23, 'Thomas', 'Bernard', "Directeurs d'Exploitation");
const PersonneDemo nadia = PersonneDemo(24, 'Nadia', 'Haddad', 'Responsable Etude RC');
const PersonneDemo elodie = PersonneDemo(25, 'Élodie', 'Perrin', 'Service Gestion');
const PersonneDemo karim = PersonneDemo(26, 'Karim', 'Benali', 'Responsables de Projet');

const List<PersonneDemo> equipeDemo = [moiDemo, julien, thomas, nadia, elodie, karim];

/// Rôles RC de l'utilisateur de démonstration (profil multi-rôles).
const List<Json> rolesDemo = [
  {'id': 3, 'nom': 'Directeurs Projet', 'libelle': 'Directeur Projet', 'etape': 'DP', 'sigle': 'DP'},
  {'id': 5, 'nom': 'Responsable Etude RC', 'libelle': "Directeur d'Études", 'etape': 'RE', 'sigle': 'DE'},
  {'id': 6, 'nom': 'Service Gestion', 'libelle': 'Service Gestion', 'etape': 'SG', 'sigle': 'SG'},
  {'id': 9, 'nom': 'Direction', 'libelle': 'Direction', 'etape': null, 'sigle': null},
];

class ProjetDemo {
  const ProjetDemo({
    required this.id,
    required this.code,
    required this.nom,
    required this.ville,
    required this.typologie,
    required this.type,
    required this.maitreOuvrage,
  });

  final int id;
  final String code;
  final String nom;
  final String ville;
  final String typologie;
  final String type;
  final String maitreOuvrage;
}

const ProjetDemo tilleuls = ProjetDemo(
  id: 101,
  code: 'LYO-24-031',
  nom: 'Résidence Les Tilleuls',
  ville: 'Villeurbanne',
  typologie: 'Logement',
  type: 'prive',
  maitreOuvrage: 'Alliade Habitat',
);
const ProjetDemo jeanMace = ProjetDemo(
  id: 102,
  code: 'GRE-23-112',
  nom: 'Groupe scolaire Jean-Macé',
  ville: 'Grenoble',
  typologie: 'Equipement',
  type: 'public',
  maitreOuvrage: 'Ville de Grenoble',
);
const ProjetDemo clinique = ProjetDemo(
  id: 103,
  code: 'ANN-25-007',
  nom: 'Clinique du Lac, extension',
  ville: 'Annecy',
  typologie: 'Santé',
  type: 'prive',
  maitreOuvrage: 'Groupe hospitalier mutualiste',
);

class EvenementDemo {
  EvenementDemo({
    required this.id,
    required this.action,
    required this.statut,
    required this.le,
    required this.acteur,
    this.cible,
    this.commentaire,
    List<Json>? pieces,
  }) : pieces = pieces ?? [];

  final int id;
  final String action;

  /// Statut du document après l'événement (inchangé pour une demande d'information).
  final String statut;
  final DateTime le;
  final PersonneDemo acteur;
  final PersonneDemo? cible;
  final String? commentaire;
  final List<Json> pieces;
}

class DocDemo {
  DocDemo({
    required this.id,
    required this.type,
    required this.codification,
    required this.intitule,
    required this.projet,
    required this.creeLe,
    required this.createur,
    required this.evenements,
    required this.fiche,
    this.numeroAvenant,
    this.parentId,
    this.version = 1,
    this.tableau,
    List<Json>? fichiers,
    this.erreurPaiement,
    this.consulteLe,
    this.consulteTableauLe,
    List<Json>? signatures,
  }) : fichiers = fichiers ?? [],
       signatures = signatures ?? [];

  final int id;
  final String type;
  final String? codification;
  final String intitule;
  final ProjetDemo projet;
  final DateTime creeLe;
  final PersonneDemo createur;
  final List<EvenementDemo> evenements;

  /// Champs de la fiche : identification, montants, paiement, conditions, contact.
  final Json fiche;
  final int? numeroAvenant;
  final int? parentId;
  int version;
  bool estBc = false;

  /// Tableau chiffré déjà au format de `GET /rc/:id/tableau`.
  final Json? tableau;
  final List<Json> fichiers;
  final String? erreurPaiement;
  DateTime? consulteLe;
  DateTime? consulteTableauLe;
  DateTime? majLe;
  final List<Json> signatures;

  String get statut => evenements.isEmpty ? 'draft' : evenements.last.statut;
  DateTime get derniereActivite => evenements.isEmpty ? creeLe : evenements.last.le;
}

// ─── Tableaux comparatifs ───────────────────────────────────────────────────

class _Article {
  const _Article(
    this.designation, {
    this.qte = 0,
    this.unite,
    this.pu = 0,
    this.prix = const [],
    this.titre = false,
    this.exclu = false,
    this.transfere = false,
    this.observation,
  });

  final String designation;
  final double qte;
  final String? unite;
  final double pu;
  final List<double?> prix;
  final bool titre;
  final bool exclu;
  final bool transfere;
  final String? observation;
}

_Article _titre(String d) => _Article(d, titre: true);

double _arrondi(double v) => (v * 100).roundToDouble() / 100;

Json _comparatif({
  required int id,
  required String nom,
  required String codification,
  required String lot,
  required List<(int, String, bool)> entreprises,
  required List<_Article> articles,
  double transfert = 0,
  double? objectif,
  String? justification,
  String statut = 'cloture',
}) {
  final comptes = articles.where((a) => !a.titre && !a.exclu).toList();
  final budgetEtude = _arrondi(comptes.fold(0.0, (s, a) => s + a.qte * a.pu));
  final etudeRecale = _arrondi(budgetEtude + transfert);
  final offres = <Json>[];
  for (var i = 0; i < entreprises.length; i++) {
    final (eid, enom, retenue) = entreprises[i];
    var total = 0.0;
    var manquants = 0;
    for (final a in comptes) {
      final pu = i < a.prix.length ? a.prix[i] : null;
      if (pu == null) {
        manquants++;
      } else {
        total += pu * a.qte;
      }
    }
    total = _arrondi(total);
    offres.add({
      'id': eid,
      'nom': enom,
      'retenue': retenue,
      'total': total,
      'ecartBudget': _arrondi(total - etudeRecale),
      'prixManquants': manquants,
    });
  }
  offres.sort((x, y) {
    final r = (y['retenue'] == true ? 1 : 0) - (x['retenue'] == true ? 1 : 0);
    return r != 0 ? r : (x['total'] as double).compareTo(y['total'] as double);
  });
  var idArticle = id * 100;
  return {
    'genre': 'COMPARATIF',
    'id': id,
    'nom': nom,
    'numero': 1,
    'codification': codification,
    'lot': lot,
    'statut': statut,
    'justification': justification,
    'totaux': {
      'budgetEtude': budgetEtude,
      'transfert': transfert,
      'etudeRecale': etudeRecale,
      'objectif': objectif ?? _arrondi(etudeRecale * 0.97),
    },
    'entreprises': offres,
    'articles': [
      for (final a in articles)
        {
          'id': ++idArticle,
          'designation': a.designation,
          'titre': a.titre,
          'exclu': a.exclu,
          'transfere': a.transfere,
          'observation': a.observation,
          'quantite': a.qte,
          'unite': a.unite,
          'puBudget': a.pu,
          'ptBudget': _arrondi(a.qte * a.pu),
          'prix': [
            for (var i = 0; i < entreprises.length; i++)
              {
                'entrepriseId': entreprises[i].$1,
                'prixUnitaire': a.titre ? null : (i < a.prix.length ? a.prix[i] : null),
                'quantite': a.titre || (i < a.prix.length ? a.prix[i] : null) == null ? null : a.qte,
                'total': a.titre
                    ? null
                    : (i < a.prix.length && a.prix[i] != null ? _arrondi(a.prix[i]! * a.qte) : null),
              },
          ],
        },
    ],
  };
}

/// Montants de la fiche d'un RC, dérivés de son tableau comparatif.
Json _montantsRc(Json tableau, {double transfertTravaux = 0, double? budgetPrestation}) {
  final totaux = tableau['totaux'] as Json;
  final retenue = (tableau['entreprises'] as List).cast<Json>().firstWhere(
    (e) => e['retenue'] == true,
    orElse: () => (tableau['entreprises'] as List).cast<Json>().first,
  );
  final montant = retenue['total'] as double;
  final recale = totaux['etudeRecale'] as double;
  final objectif = totaux['objectif'] as double;
  final objectifRecale = _arrondi(objectif + transfertTravaux);
  return {
    'budgetPrestation': budgetPrestation ?? _arrondi(recale * 1.06),
    'budgetEtude': totaux['budgetEtude'],
    'transfertEtude': totaux['transfert'],
    'budgetEtudeRecale': recale,
    'objectifTravaux': objectif,
    'transfertTravaux': transfertTravaux,
    'objectifTravauxRecale': objectifRecale,
    'ecartsSstEtude': _arrondi(recale - montant),
    'ecartsSstTravaux': _arrondi(objectifRecale - montant),
    'montantRetenu': montant,
    'montantDepuisTableauExplicatif': false,
    'avenant': null,
  };
}

List<Json> _entreprisesConsultees(Json tableau, Map<String, String> observations) => [
  for (final e in (tableau['entreprises'] as List).cast<Json>())
    {
      'id': 3000 + (e['id'] as int),
      'nom': e['nom'],
      'montant': e['total'],
      'observations': observations[e['nom']],
      'retenue': e['retenue'],
    },
];

Json _paiement(double? montant, {double direct = 0, double coredif = 100}) => {
  'directPourcentage': direct,
  'directMontant': montant == null ? null : _arrondi(montant * direct / 100),
  'coredifPourcentage': coredif,
  'coredifMontant': montant == null ? null : _arrondi(montant * coredif / 100),
  'libelle': 'Direct ${_pct(direct)} % · COREDIF ${_pct(coredif)} %',
};

String _pct(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString().replaceAll('.', ',');

Json _piece(int id, String nom, int taille, String type, String categorie, DateTime le) => {
  'id': id,
  'nom': nom,
  'taille': taille,
  'type': type,
  'deposeLe': le.toUtc().toIso8601String(),
  'categorie': categorie,
};

Json _fichier(
  int id,
  String nom,
  int taille,
  String type,
  DateTime le, {
  String? dossier,
  String? description,
  (String, String)? categorie,
  PersonneDemo? par,
}) => {
  'id': id,
  'nom': nom,
  'taille': taille,
  'type': type,
  'deposeLe': le.toUtc().toIso8601String(),
  'dossier': dossier,
  'description': description,
  'categorie': categorie == null ? null : {'nom': categorie.$1, 'couleur': categorie.$2},
  'deposePar': par?.nomComplet,
};

const String _pdf = 'application/pdf';
const String _jpeg = 'image/jpeg';

/// Le monde de démonstration, reconstruit à chaque lancement.
class MondeDemo {
  MondeDemo(this.t0) {
    _construire();
  }

  final DateTime t0;
  final Map<int, DocDemo> docs = {};
  final List<Json> notifications = [];
  final List<Json> sessions = [];

  DateTime il({int jours = 0, int heures = 0, int minutes = 0}) =>
      t0.subtract(Duration(days: jours, hours: heures, minutes: minutes));

  void _ajouter(DocDemo d) => docs[d.id] = d;

  void _construire() {
    // ── 142 : RC envoyé par le RP, chez le DP (à décider) ───────────────────
    final tc142 = _comparatif(
      id: 801,
      nom: 'TC Gros œuvre — bâtiment A',
      codification: 'LYO-24-031-TC-014',
      lot: 'Lot 02 — Gros œuvre',
      transfert: -12000,
      objectif: 1289000,
      justification:
          'Bâti Rhône retenue après négociation : mieux-disante sur la superstructure, '
          "délais compatibles avec le planning de l'OPC. Ossature Alpes n'a pas chiffré les reprises en sous-œuvre.",
      entreprises: [
        (11, 'Bâti Rhône Construction', true),
        (12, 'Maçonnerie Gaillard & Fils', false),
        (13, 'Ossature Alpes BTP', false),
      ],
      articles: [
        _titre('Terrassements et fondations'),
        const _Article('Terrassement en pleine masse', qte: 2850, unite: 'm³', pu: 18.5, prix: [17.2, 19.8, 18.9]),
        const _Article('Semelles filantes béton armé', qte: 420, unite: 'm³', pu: 265, prix: [258, 279, 271]),
        const _Article('Reprises en sous-œuvre mitoyen', qte: 1, unite: 'ens', pu: 48000, prix: [44500, 51200, null]),
        _titre('Superstructure'),
        const _Article('Voiles béton banché ép. 20 cm', qte: 3150, unite: 'm²', pu: 112, prix: [108.5, 116, 110]),
        const _Article('Planchers dalle pleine ép. 22 cm', qte: 4280, unite: 'm²', pu: 96, prix: [93.8, 99.5, 97.2]),
        const _Article('Poteaux et poutres BA', qte: 185, unite: 'm³', pu: 610, prix: [598, 640, 615]),
        const _Article(
          'Escaliers préfabriqués',
          qte: 6,
          unite: 'u',
          pu: 7800,
          prix: [7650, 8100, 7900],
          transfere: true,
        ),
        const _Article(
          'Option : façade matricée',
          qte: 1,
          unite: 'ens',
          pu: 36000,
          prix: [34000, 38500, 35200],
          exclu: true,
          observation: 'Option non retenue par la MOA (CR du 12/09).',
        ),
      ],
    );
    final m142 = _montantsRc(tc142, budgetPrestation: 1525000);
    _ajouter(
      DocDemo(
        id: 142,
        type: 'RC',
        codification: 'LYO-24-031-RC-014',
        intitule: 'Gros œuvre — bâtiment A',
        projet: tilleuls,
        creeLe: il(jours: 9, heures: 3),
        createur: julien,
        tableau: tc142,
        fiche: {
          'corpsEtat': 'Gros œuvre',
          'prestation': 'Fondations, superstructure et escaliers du bâtiment A',
          'numeroLot': '02',
          'dateDebut': 'Semaine 45 (4 novembre)',
          'dateFin': DateTime(t0.year + 1, 6, 30).toUtc().toIso8601String(),
          'montants': m142,
          'paiement': _paiement(m142['montantRetenu'] as double),
          'conditions': {
            'insertion': true,
            'nbreHeuresInsertion': 350,
            'prorata': true,
            'pourcentageProrata': '1,5',
            'retenue5Rg': true,
            'retenue5BonneFin': false,
            'dc4Modificatif': false,
          },
          'entreprise': {
            'chargeAffaire': 'Marc Delorme',
            'email': 'm.delorme@batirhone.example',
            'telephone': '04 78 12 34 56',
            'sousTraitantRang2': null,
          },
          'entreprisesConsultees': _entreprisesConsultees(tc142, {
            'Bâti Rhône Construction': 'Offre négociée le 8/10, remise de 2,5 %.',
            'Ossature Alpes BTP': 'Reprises en sous-œuvre non chiffrées.',
          }),
          'commentaire': 'Démarrage conditionné à la libération de la plateforme par le lot VRD.',
        },
        signatures: [
          {'par': julien.nomComplet, 'type': 'RP', 'le': il(heures: 2).toUtc().toIso8601String()},
        ],
        evenements: [
          EvenementDemo(
            id: 1001,
            action: 'APPROVED_BY_RESPONSABLE_PROJET',
            statut: 'approved_by_responsable_projet',
            le: il(heures: 2, minutes: 10),
            acteur: julien,
            commentaire:
                "Planning recalé avec l'entreprise : démarrage le 4 novembre. Offre la mieux-disante après négociation.",
            pieces: [
              _piece(7001, 'Compte rendu de négociation.pdf', 421340, _pdf, 'approval', il(heures: 2, minutes: 9)),
            ],
          ),
        ],
        fichiers: [
          _fichier(
            7101,
            'CCTP lot 02 — Gros œuvre.pdf',
            2841200,
            _pdf,
            il(jours: 9),
            categorie: ('Marché', '#1D539D'),
            par: julien,
          ),
          _fichier(
            7102,
            'Plan R+1 indice C.pdf',
            5120400,
            _pdf,
            il(jours: 8),
            dossier: 'Plans',
            categorie: ('Plans', '#507EBC'),
            par: julien,
          ),
          _fichier(
            7103,
            'Plan fondations indice B.pdf',
            3480100,
            _pdf,
            il(jours: 8),
            dossier: 'Plans',
            categorie: ('Plans', '#507EBC'),
            par: julien,
          ),
          _fichier(
            7104,
            'Offre Bâti Rhône Construction.pdf',
            1250900,
            _pdf,
            il(jours: 5),
            dossier: 'Offres',
            categorie: ('Offres', '#1A7A4C'),
            par: julien,
          ),
          _fichier(
            7105,
            'Attestation décennale 2025.pdf',
            312000,
            _pdf,
            il(jours: 5),
            dossier: 'Administratif',
            par: julien,
          ),
        ],
      ),
    );

    // ── 143 : RC rejeté par le DEX, revenu chez le DP, paiement incohérent ──
    final tc143 = _comparatif(
      id: 802,
      nom: 'TC Menuiseries extérieures',
      codification: 'GRE-23-112-TC-009',
      lot: 'Lot 07 — Menuiseries extérieures aluminium',
      transfert: 8500,
      entreprises: [(21, 'Alu Concept Isère', true), (22, 'Menuiseries du Vercors', false)],
      articles: [
        _titre('Châssis'),
        const _Article('Fenêtres alu 2 vantaux 135×125', qte: 64, unite: 'u', pu: 1180, prix: [1150, 1215]),
        const _Article('Portes-fenêtres alu 215×140', qte: 22, unite: 'u', pu: 1890, prix: [1920, 1860]),
        const _Article('Murs-rideaux hall', qte: 86, unite: 'm²', pu: 640, prix: [655, 690]),
        _titre('Occultations'),
        const _Article('Brise-soleil orientables motorisés', qte: 58, unite: 'u', pu: 780, prix: [745, 810]),
      ],
    );
    final m143 = _montantsRc(tc143, transfertTravaux: 4000);
    _ajouter(
      DocDemo(
        id: 143,
        type: 'RC',
        codification: 'GRE-23-112-RC-009',
        intitule: 'Menuiseries extérieures aluminium',
        projet: jeanMace,
        creeLe: il(jours: 14),
        createur: karim,
        version: 2,
        tableau: tc143,
        erreurPaiement:
            'La somme des pourcentages de paiement Direct et COREDIF doit être égale à 100 % (actuellement 105 %)',
        consulteLe: il(jours: 4, heures: 2),
        consulteTableauLe: il(jours: 4, heures: 2),
        fiche: {
          'corpsEtat': 'Menuiseries extérieures',
          'prestation': 'Fourniture et pose des menuiseries aluminium et occultations',
          'numeroLot': '07',
          'dateDebut': 'Janvier',
          'dateFin': DateTime(t0.year + 1, 4, 15).toUtc().toIso8601String(),
          'montants': m143,
          'paiement': {..._paiement(m143['montantRetenu'] as double, direct: 60, coredif: 45), 'erreur': null},
          'conditions': {
            'insertion': false,
            'nbreHeuresInsertion': null,
            'prorata': true,
            'pourcentageProrata': '2',
            'retenue5Rg': true,
            'retenue5BonneFin': true,
            'dc4Modificatif': false,
          },
          'entreprise': {
            'chargeAffaire': 'Laure Vidal',
            'email': 'laure.vidal@aluconcept.example',
            'telephone': '04 76 45 22 10',
            'sousTraitantRang2': 'Vitrages Rhône-Alpes (miroiterie)',
          },
          'entreprisesConsultees': _entreprisesConsultees(tc143, {
            'Menuiseries du Vercors': 'Délai de fabrication 14 semaines.',
          }),
          'commentaire': null,
        },
        signatures: [
          {'par': karim.nomComplet, 'type': 'RP', 'le': il(jours: 6).toUtc().toIso8601String()},
          {'par': moiDemo.nomComplet, 'type': 'DP', 'le': il(jours: 4).toUtc().toIso8601String()},
        ],
        evenements: [
          EvenementDemo(
            id: 1101,
            action: 'APPROVED_BY_RESPONSABLE_PROJET',
            statut: 'approved_by_responsable_projet',
            le: il(jours: 6),
            acteur: karim,
            commentaire: 'Envoi pour validation.',
          ),
          EvenementDemo(
            id: 1102,
            action: 'APPROVED_BY_DIRECTEUR_PROJET',
            statut: 'approved_by_directeur_projet',
            le: il(jours: 4),
            acteur: moiDemo,
            commentaire: 'Offre conforme au CCTP.',
          ),
          EvenementDemo(
            id: 1103,
            action: 'REJECTED_BY_DIRECTEUR_EXPLOITATION',
            statut: 'rejected_by_directeur_exploitation',
            le: il(jours: 1, heures: 3),
            acteur: thomas,
            cible: moiDemo,
            commentaire:
                'La répartition du paiement ne tombe pas juste : 60 % en direct et 45 % COREDIF. '
                "Merci de faire corriger, et de joindre l'attestation décennale à jour.",
            pieces: [
              _piece(7002, 'Photo menuiseries posées.jpg', 2316800, _jpeg, 'rejection', il(jours: 1, heures: 3)),
            ],
          ),
        ],
        fichiers: [
          _fichier(7201, 'CCTP lot 07.pdf', 1984000, _pdf, il(jours: 14), categorie: ('Marché', '#1D539D'), par: karim),
          _fichier(
            7202,
            'Carnet de détails menuiseries.pdf',
            6240000,
            _pdf,
            il(jours: 12),
            dossier: 'Plans',
            par: karim,
          ),
        ],
      ),
    );

    // ── 140 : RC d'origine de l'avenant 144, validé ──────────────────────────
    final tc140 = _comparatif(
      id: 803,
      nom: 'TC Électricité courants forts',
      codification: 'GRE-23-112-TC-004',
      lot: 'Lot 11 — Électricité CFO',
      entreprises: [(31, 'Elec Dauphiné', true), (32, 'Volta Services', false), (33, 'Lumen Électricité', false)],
      articles: [
        const _Article('Distribution et TGBT', qte: 1, unite: 'ens', pu: 86000, prix: [84200, 89900, 87500]),
        const _Article('Éclairage intérieur LED', qte: 412, unite: 'u', pu: 185, prix: [176, 194, 181]),
        const _Article('Prises et circuits terminaux', qte: 1, unite: 'ens', pu: 52000, prix: [50400, 55100, 53800]),
      ],
    );
    final m140 = _montantsRc(tc140);
    _ajouter(
      DocDemo(
        id: 140,
        type: 'RC',
        codification: 'GRE-23-112-RC-004',
        intitule: 'Électricité courants forts',
        projet: jeanMace,
        creeLe: il(jours: 120),
        createur: karim,
        tableau: tc140,
        fiche: _ficheSimple(m140, tc140, 'Électricité', '11'),
        signatures: _signaturesCompletes(il(jours: 96)),
        evenements: _circuitComplet(1201, il(jours: 100), karim),
        fichiers: [_fichier(7301, 'CCTP lot 11.pdf', 1650000, _pdf, il(jours: 120), par: karim)],
      ),
    );

    // ── 144 : avenant 1 du RC 140, chez le DP (tableau explicatif) ──────────
    final te144 = <String, dynamic>{
      'genre': 'EXPLICATIF',
      'id': 901,
      'codification': 'GRE-23-112-TE-004-1',
      'statut': 'cloture',
      'cloture': true,
      'fgTaux': 0.05,
      'commentaires': 'Travaux supplémentaires demandés par la MOA par OS n°7 (éclairage du préau, alimentation CVC).',
      'lignes': [
        {
          'id': 9011,
          'designation': 'Éclairage du préau (OS n°7)',
          'isSousLigne': false,
          'osNumero': '7',
          'numeroDevisClient': 'DV-2025-118',
          'montantClient': 31800.0,
          'montantStClient': 26400.0,
          'provenanceBudget': null,
          'montantBudgetTravaux': null,
          'montantStNonClient': null,
          'fg': 1320.0,
          'margeClient': 4080.0,
          'margeNonClient': 0.0,
        },
        {
          'id': 9012,
          'designation': 'Luminaires LED étanches IP65 (12 u)',
          'isSousLigne': true,
          'osNumero': '7',
          'numeroDevisClient': 'DV-2025-118',
          'montantClient': 9600.0,
          'montantStClient': 8100.0,
          'provenanceBudget': null,
          'montantBudgetTravaux': null,
          'montantStNonClient': null,
          'fg': 405.0,
          'margeClient': 1095.0,
          'margeNonClient': 0.0,
        },
        {
          'id': 9013,
          'designation': 'Alimentation prises CVC, local technique',
          'isSousLigne': false,
          'osNumero': null,
          'numeroDevisClient': null,
          'montantClient': null,
          'montantStClient': null,
          'provenanceBudget': 'Lot CVC (transfert)',
          'montantBudgetTravaux': 7250.0,
          'montantStNonClient': 6700.0,
          'fg': 335.0,
          'margeClient': 0.0,
          'margeNonClient': 215.0,
        },
      ],
      'totaux': {
        'totalMontantClient': 41400.0,
        'totalMontantStClient': 34500.0,
        'totalFg': 2060.0,
        'totalBudgetTravaux': 7250.0,
        'totalMontantStNonClient': 6700.0,
        'montantAvenant': 48650.0,
        'marge': 5390.0,
        'budgetTravaux': 43530.0,
        'ecartSstObjectifTravaux': 2330.0,
      },
    };
    _ajouter(
      DocDemo(
        id: 144,
        type: 'AVENANT',
        numeroAvenant: 1,
        parentId: 140,
        codification: 'GRE-23-112-RC-004-AV1',
        intitule: 'Électricité courants forts',
        projet: jeanMace,
        creeLe: il(jours: 3),
        createur: karim,
        tableau: te144,
        fiche: {
          'corpsEtat': 'Électricité',
          'prestation': 'Travaux supplémentaires OS n°7',
          'numeroLot': '11',
          'dateDebut': 'Vacances de printemps',
          'dateFin': null,
          'montants': {
            'budgetPrestation': null,
            'budgetEtude': null,
            'transfertEtude': null,
            'budgetEtudeRecale': null,
            'objectifTravaux': null,
            'transfertTravaux': null,
            'objectifTravauxRecale': null,
            'ecartsSstEtude': null,
            'ecartsSstTravaux': null,
            'montantRetenu': 48650.0,
            'montantDepuisTableauExplicatif': true,
            'avenant': {'montantHt': 48650.0, 'budgetTravaux': 43530.0, 'marge': 5390.0, 'ecart': 2330.0},
          },
          'paiement': _paiement(48650),
          'conditions': {
            'insertion': false,
            'nbreHeuresInsertion': null,
            'prorata': false,
            'pourcentageProrata': null,
            'retenue5Rg': true,
            'retenue5BonneFin': false,
            'dc4Modificatif': true,
          },
          'entreprise': {
            'chargeAffaire': 'Hugo Fabre',
            'email': 'h.fabre@elecdauphine.example',
            'telephone': '04 76 98 76 54',
            'sousTraitantRang2': null,
          },
          'entreprisesConsultees': [
            {'id': 3031, 'nom': 'Elec Dauphiné', 'montant': 48650.0, 'observations': null, 'retenue': true},
          ],
          'commentaire': null,
        },
        signatures: [
          {'par': karim.nomComplet, 'type': 'RP', 'le': il(jours: 1).toUtc().toIso8601String()},
        ],
        evenements: [
          EvenementDemo(
            id: 1301,
            action: 'APPROVED_BY_RESPONSABLE_PROJET',
            statut: 'approved_by_responsable_projet',
            le: il(jours: 1, heures: 1),
            acteur: karim,
            commentaire: 'Travaux supplémentaires demandés par la MOA (OS n°7) : éclairage du préau et prises CVC.',
            pieces: [_piece(7003, 'OS n°7 signé.pdf', 188400, _pdf, 'approval', il(jours: 1, heures: 1))],
          ),
        ],
        fichiers: [
          _fichier(
            7401,
            'Devis Elec Dauphiné DV-2025-118.pdf',
            402000,
            _pdf,
            il(jours: 3),
            dossier: 'Devis',
            par: karim,
          ),
        ],
      ),
    );

    // ── 145 : RC approuvé par moi (DP), chez le DEX ─────────────────────────
    final tc145 = _comparatif(
      id: 804,
      nom: 'TC Plomberie CVC',
      codification: 'ANN-25-007-TC-003',
      lot: 'Lot 12 — Plomberie, CVC',
      entreprises: [(41, 'Thermi Savoie', true), (42, 'Clim Léman', false)],
      articles: [
        const _Article('Production de chaleur (PAC)', qte: 2, unite: 'u', pu: 68000, prix: [66500, 71200]),
        const _Article('Réseaux de ventilation double flux', qte: 1, unite: 'ens', pu: 142000, prix: [139800, 148000]),
        const _Article('Appareils sanitaires', qte: 96, unite: 'u', pu: 420, prix: [405, 438]),
      ],
    );
    final m145 = _montantsRc(tc145);
    _ajouter(
      DocDemo(
        id: 145,
        type: 'RC',
        codification: 'ANN-25-007-RC-003',
        intitule: 'Plomberie, CVC',
        projet: clinique,
        creeLe: il(jours: 11),
        createur: julien,
        tableau: tc145,
        consulteLe: il(jours: 3, heures: 1),
        consulteTableauLe: il(jours: 3, heures: 1),
        fiche: _ficheSimple(m145, tc145, 'Plomberie, CVC', '12'),
        signatures: [
          {'par': julien.nomComplet, 'type': 'RP', 'le': il(jours: 5).toUtc().toIso8601String()},
          {'par': moiDemo.nomComplet, 'type': 'DP', 'le': il(jours: 3).toUtc().toIso8601String()},
        ],
        evenements: [
          EvenementDemo(
            id: 1401,
            action: 'APPROVED_BY_RESPONSABLE_PROJET',
            statut: 'approved_by_responsable_projet',
            le: il(jours: 5),
            acteur: julien,
          ),
          EvenementDemo(
            id: 1402,
            action: 'APPROVED_BY_DIRECTEUR_PROJET',
            statut: 'approved_by_directeur_projet',
            le: il(jours: 3),
            acteur: moiDemo,
            commentaire: 'Bon pour accord, vigilance sur le délai des PAC.',
          ),
        ],
      ),
    );

    // ── 146 : chez le DE, qui me demande une information ────────────────────
    final tc146 = _comparatif(
      id: 805,
      nom: 'TC Façades ITE',
      codification: 'LYO-24-031-TC-011',
      lot: 'Lot 04 — Isolation thermique par l’extérieur',
      transfert: 15000,
      entreprises: [
        (51, 'Façades Lyonnaises', true),
        (52, 'Isolat Rhône', false),
        (53, 'Enduits du Beaujolais', false),
      ],
      articles: [
        const _Article('ITE laine de bois ép. 16 cm + enduit', qte: 2950, unite: 'm²', pu: 118, prix: [124, 131, 127]),
        const _Article('Bandes coupe-feu', qte: 640, unite: 'ml', pu: 32, prix: [30, 35, null]),
        const _Article('Échafaudages', qte: 1, unite: 'ens', pu: 38000, prix: [36500, 41000, 39800]),
      ],
    );
    final m146 = _montantsRc(tc146);
    _ajouter(
      DocDemo(
        id: 146,
        type: 'RC',
        codification: 'LYO-24-031-RC-011',
        intitule: 'Façades — isolation thermique par l’extérieur',
        projet: tilleuls,
        creeLe: il(jours: 16),
        createur: julien,
        tableau: tc146,
        consulteLe: il(jours: 4),
        consulteTableauLe: il(jours: 4),
        fiche: _ficheSimple(m146, tc146, 'Façades', '04'),
        signatures: [
          {'par': julien.nomComplet, 'type': 'RP', 'le': il(jours: 6).toUtc().toIso8601String()},
          {'par': moiDemo.nomComplet, 'type': 'DP', 'le': il(jours: 4).toUtc().toIso8601String()},
          {'par': thomas.nomComplet, 'type': 'DEX', 'le': il(jours: 2).toUtc().toIso8601String()},
        ],
        evenements: [
          EvenementDemo(
            id: 1501,
            action: 'APPROVED_BY_RESPONSABLE_PROJET',
            statut: 'approved_by_responsable_projet',
            le: il(jours: 6),
            acteur: julien,
          ),
          EvenementDemo(
            id: 1502,
            action: 'APPROVED_BY_DIRECTEUR_PROJET',
            statut: 'approved_by_directeur_projet',
            le: il(jours: 4),
            acteur: moiDemo,
          ),
          EvenementDemo(
            id: 1503,
            action: 'APPROVED_BY_DIRECTEUR_EXPLOITATION',
            statut: 'approved_by_directeur_exploitation',
            le: il(jours: 2),
            acteur: thomas,
            commentaire: 'OK exploitation.',
          ),
          EvenementDemo(
            id: 1504,
            action: 'INFO_REQUEST_BY_RESPONSABLE_ETUDE_TO_DIRECTEUR_PROJET',
            statut: 'approved_by_directeur_exploitation',
            le: il(heures: 5),
            acteur: nadia,
            cible: moiDemo,
            commentaire:
                'Pouvez-vous confirmer que la variante laine de bois a été validée par le bureau de contrôle ? '
                "Le surcoût n'apparaît pas dans le budget recalé.",
            pieces: [_piece(7004, 'Avis BC variante ITE.pdf', 264000, _pdf, 'info_request', il(heures: 5))],
          ),
        ],
      ),
    );

    // ── 147 : circuit terminé ───────────────────────────────────────────────
    final tc147 = _comparatif(
      id: 806,
      nom: 'TC Électricité CFO / CFA',
      codification: 'ANN-25-007-TC-001',
      lot: 'Lot 13 — Électricité',
      entreprises: [(61, 'Savoie Électricité', true), (62, 'Volta Services', false)],
      articles: [
        const _Article('Courants forts', qte: 1, unite: 'ens', pu: 212000, prix: [208500, 219000]),
        const _Article('Courants faibles et SSI', qte: 1, unite: 'ens', pu: 96000, prix: [94800, 99900]),
      ],
    );
    _ajouter(
      DocDemo(
        id: 147,
        type: 'RC',
        codification: 'ANN-25-007-RC-001',
        intitule: 'Électricité CFO / CFA',
        projet: clinique,
        creeLe: il(jours: 40),
        createur: julien,
        tableau: tc147,
        fiche: _ficheSimple(_montantsRc(tc147), tc147, 'Électricité', '13'),
        signatures: _signaturesCompletes(il(jours: 10)),
        evenements: _circuitComplet(1601, il(jours: 14), julien),
      ),
    );

    // ── 148 : approuvé par le DE, chez le SG (conversion BC possible) ──────
    final tc148 = _comparatif(
      id: 807,
      nom: 'TC Peinture, sols souples',
      codification: 'GRE-23-112-TC-012',
      lot: 'Lot 09 — Peinture, sols souples',
      entreprises: [(71, 'Couleurs & Sols', true), (72, 'Atelier Peinture Alpes', false)],
      articles: [
        const _Article('Peinture murs et plafonds', qte: 6200, unite: 'm²', pu: 14.5, prix: [15.2, 16.1]),
        const _Article('Sols PVC acoustiques', qte: 1850, unite: 'm²', pu: 42, prix: [44.5, 41.8]),
        const _Article('Reprise des supports', qte: 1, unite: 'ens', pu: 9000, prix: [12500, 14800]),
      ],
    );
    _ajouter(
      DocDemo(
        id: 148,
        type: 'RC',
        codification: 'GRE-23-112-RC-012',
        intitule: 'Peinture, sols souples',
        projet: jeanMace,
        creeLe: il(jours: 20),
        createur: karim,
        tableau: tc148,
        fiche: _ficheSimple(_montantsRc(tc148), tc148, 'Peinture', '09'),
        signatures: [
          {'par': karim.nomComplet, 'type': 'RP', 'le': il(jours: 8).toUtc().toIso8601String()},
          {'par': moiDemo.nomComplet, 'type': 'DP', 'le': il(jours: 6).toUtc().toIso8601String()},
          {'par': thomas.nomComplet, 'type': 'DEX', 'le': il(jours: 3).toUtc().toIso8601String()},
          {'par': nadia.nomComplet, 'type': 'DE', 'le': il(heures: 6).toUtc().toIso8601String()},
        ],
        evenements: [
          EvenementDemo(
            id: 1701,
            action: 'APPROVED_BY_RESPONSABLE_PROJET',
            statut: 'approved_by_responsable_projet',
            le: il(jours: 8),
            acteur: karim,
          ),
          EvenementDemo(
            id: 1702,
            action: 'APPROVED_BY_DIRECTEUR_PROJET',
            statut: 'approved_by_directeur_projet',
            le: il(jours: 6),
            acteur: moiDemo,
          ),
          EvenementDemo(
            id: 1703,
            action: 'APPROVED_BY_DIRECTEUR_EXPLOITATION',
            statut: 'approved_by_directeur_exploitation',
            le: il(jours: 3),
            acteur: thomas,
          ),
          EvenementDemo(
            id: 1704,
            action: 'APPROVED_BY_RESPONSABLE_ETUDE',
            statut: 'approved_by_responsable_etude',
            le: il(heures: 6),
            acteur: nadia,
            commentaire: 'Écart justifié par la reprise des supports (voir tableau).',
          ),
        ],
        fichiers: [
          _fichier(7501, 'Offre Couleurs & Sols.pdf', 845000, _pdf, il(jours: 20), dossier: 'Offres', par: karim),
        ],
      ),
    );

    // ── 149 : brouillon chez le RP ──────────────────────────────────────────
    _ajouter(
      DocDemo(
        id: 149,
        type: 'RC',
        codification: null,
        intitule: 'Ascenseurs',
        projet: tilleuls,
        creeLe: il(jours: 1, heures: 6),
        createur: julien,
        evenements: [],
        fiche: {
          'corpsEtat': 'Ascenseurs',
          'prestation': null,
          'numeroLot': '15',
          'dateDebut': null,
          'dateFin': null,
          'montants': const {'montantDepuisTableauExplicatif': false},
          'paiement': const {},
          'conditions': const {},
          'entreprise': const {},
          'entreprisesConsultees': const <Json>[],
          'commentaire': null,
        },
      ),
    );

    // ── 150 : renvoyé par le SG au DE ───────────────────────────────────────
    final tc150 = _comparatif(
      id: 808,
      nom: 'TC Cloisons, doublages',
      codification: 'ANN-25-007-TC-005',
      lot: 'Lot 08 — Plâtrerie',
      entreprises: [(81, 'Plâtrerie Savoyarde', true), (82, 'Cloisons Express', false)],
      articles: [
        const _Article('Cloisons 98/48 EI60', qte: 2400, unite: 'm²', pu: 48, prix: [46.5, 51]),
        const _Article('Doublages thermiques', qte: 1800, unite: 'm²', pu: 36, prix: [37.2, 34.9]),
      ],
    );
    _ajouter(
      DocDemo(
        id: 150,
        type: 'RC',
        codification: 'ANN-25-007-RC-005',
        intitule: 'Cloisons, doublages',
        projet: clinique,
        creeLe: il(jours: 25),
        createur: julien,
        tableau: tc150,
        consulteTableauLe: il(jours: 2),
        fiche: _ficheSimple(_montantsRc(tc150), tc150, 'Plâtrerie', '08'),
        signatures: [
          {'par': julien.nomComplet, 'type': 'RP', 'le': il(jours: 9).toUtc().toIso8601String()},
          {'par': moiDemo.nomComplet, 'type': 'DP', 'le': il(jours: 7).toUtc().toIso8601String()},
          {'par': thomas.nomComplet, 'type': 'DEX', 'le': il(jours: 5).toUtc().toIso8601String()},
          {'par': nadia.nomComplet, 'type': 'DE', 'le': il(jours: 2).toUtc().toIso8601String()},
        ],
        evenements: [
          EvenementDemo(
            id: 1801,
            action: 'APPROVED_BY_RESPONSABLE_PROJET',
            statut: 'approved_by_responsable_projet',
            le: il(jours: 9),
            acteur: julien,
          ),
          EvenementDemo(
            id: 1802,
            action: 'APPROVED_BY_DIRECTEUR_PROJET',
            statut: 'approved_by_directeur_projet',
            le: il(jours: 7),
            acteur: moiDemo,
          ),
          EvenementDemo(
            id: 1803,
            action: 'APPROVED_BY_DIRECTEUR_EXPLOITATION',
            statut: 'approved_by_directeur_exploitation',
            le: il(jours: 5),
            acteur: thomas,
          ),
          EvenementDemo(
            id: 1804,
            action: 'APPROVED_BY_RESPONSABLE_ETUDE',
            statut: 'approved_by_responsable_etude',
            le: il(jours: 2),
            acteur: nadia,
          ),
          EvenementDemo(
            id: 1805,
            action: 'REJECTED_BY_SERVICE_GESTION_TO_RESPONSABLE_ETUDE',
            statut: 'rejected_by_service_gestion_to_responsable_etude',
            le: il(heures: 3),
            acteur: elodie,
            cible: nadia,
            commentaire:
                "Le DC4 modificatif n'est pas joint alors que le sous-traitant de rang 2 a changé. Merci de le demander à l'entreprise.",
          ),
        ],
      ),
    );

    // ── Notifications (les plus récentes en premier) ────────────────────────
    notifications.addAll([
      _notif(
        5016,
        'RC_APPROVAL_REQUIRED',
        'RC à valider',
        '${julien.nomComplet} a envoyé LYO-24-031-RC-014 (Gros œuvre — bâtiment A) pour validation.',
        il(heures: 2, minutes: 10),
        142,
        tilleuls.id,
        julien,
        lue: false,
      ),
      _notif(
        5015,
        'RC_INFO_REQUESTED',
        "Demande d'information",
        '${nadia.nomComplet} vous demande une information sur LYO-24-031-RC-011 (Façades).',
        il(heures: 5),
        146,
        tilleuls.id,
        nadia,
        lue: false,
      ),
      _notif(
        5014,
        'RC_REJECTED',
        'RC renvoyé',
        '${thomas.nomComplet} a rejeté GRE-23-112-RC-009 (Menuiseries extérieures) : paiement à corriger.',
        il(jours: 1, heures: 3),
        143,
        jeanMace.id,
        thomas,
        lue: false,
      ),
      _notif(
        5013,
        'RC_APPROVAL_REQUIRED',
        'Avenant à valider',
        "${karim.nomComplet} a envoyé l'avenant 1 de GRE-23-112-RC-004 (Électricité courants forts).",
        il(jours: 1, heures: 1),
        144,
        jeanMace.id,
        karim,
        lue: true,
      ),
      _notif(
        5012,
        'RC_APPROVED',
        'RC transmis',
        "ANN-25-007-RC-003 (Plomberie, CVC) est chez le Directeur d'Exploitation.",
        il(jours: 3),
        145,
        clinique.id,
        moiDemo,
        lue: true,
      ),
      _notif(
        5011,
        'RC_VALIDATED',
        'Circuit terminé',
        'ANN-25-007-RC-001 (Électricité CFO / CFA) a été validé par le Service Gestion.',
        il(jours: 10),
        147,
        clinique.id,
        elodie,
        lue: true,
      ),
      _notif(
        5010,
        'RC_PROJECT_ASSIGNED',
        'Nouveau projet',
        'Vous êtes affecté au projet ANN-25-007 Clinique du Lac, extension.',
        il(jours: 26),
        null,
        clinique.id,
        null,
        lue: true,
      ),
    ]);

    sessions.addAll([
      {
        'sid': '8b0e6f6c-5f0a-4d55-9a3e-0b6a1c2d3e4f',
        'appareil': 'Google Pixel 8',
        'plateforme': 'android',
        'creeLe': il(jours: 2).toUtc().toIso8601String(),
        'utiliseLe': t0.toUtc().toIso8601String(),
        'courante': true,
      },
      {
        'sid': '1f7d2c9a-0e4b-4c3a-8f6e-5d4c3b2a1908',
        'appareil': 'Apple iPhone 15 Pro',
        'plateforme': 'ios',
        'creeLe': il(jours: 30).toUtc().toIso8601String(),
        'utiliseLe': il(jours: 3).toUtc().toIso8601String(),
        'courante': false,
      },
      {
        'sid': '5a6b7c8d-9e0f-4a1b-8c2d-3e4f5a6b7c8d',
        'appareil': 'Samsung Galaxy Tab S9',
        'plateforme': 'android',
        'creeLe': il(jours: 60).toUtc().toIso8601String(),
        'utiliseLe': il(jours: 21).toUtc().toIso8601String(),
        'courante': false,
      },
    ]);
  }

  Json _notif(
    int id,
    String type,
    String titre,
    String message,
    DateTime le,
    int? rcId,
    int? projetId,
    PersonneDemo? acteur, {
    required bool lue,
  }) => {
    'id': id,
    'type': type,
    'titre': titre,
    'message': message,
    'lue': lue,
    'le': le.toUtc().toIso8601String(),
    'rcId': rcId,
    'projetId': projetId,
    'acteur': acteur?.nomComplet,
  };

  Json _ficheSimple(Json montants, Json tableau, String corpsEtat, String lot) => {
    'corpsEtat': corpsEtat,
    'prestation': null,
    'numeroLot': lot,
    'dateDebut': null,
    'dateFin': null,
    'montants': montants,
    'paiement': _paiement(montants['montantRetenu'] as double?),
    'conditions': {
      'insertion': false,
      'nbreHeuresInsertion': null,
      'prorata': true,
      'pourcentageProrata': '1,5',
      'retenue5Rg': true,
      'retenue5BonneFin': false,
      'dc4Modificatif': false,
    },
    'entreprise': {'chargeAffaire': null, 'email': null, 'telephone': null, 'sousTraitantRang2': null},
    'entreprisesConsultees': _entreprisesConsultees(tableau, const {}),
    'commentaire': null,
  };

  List<Json> _signaturesCompletes(DateTime fin) => [
    for (final (i, (p, sigle)) in [
      (julien, 'RP'),
      (moiDemo, 'DP'),
      (thomas, 'DEX'),
      (nadia, 'DE'),
      (elodie, 'SG'),
    ].indexed)
      {'par': p.nomComplet, 'type': sigle, 'le': fin.subtract(Duration(days: (4 - i) * 2)).toUtc().toIso8601String()},
  ];

  List<EvenementDemo> _circuitComplet(int premierId, DateTime fin, PersonneDemo rp) => [
    EvenementDemo(
      id: premierId,
      action: 'APPROVED_BY_RESPONSABLE_PROJET',
      statut: 'approved_by_responsable_projet',
      le: fin.subtract(const Duration(days: 8)),
      acteur: rp,
    ),
    EvenementDemo(
      id: premierId + 1,
      action: 'APPROVED_BY_DIRECTEUR_PROJET',
      statut: 'approved_by_directeur_projet',
      le: fin.subtract(const Duration(days: 6)),
      acteur: moiDemo,
    ),
    EvenementDemo(
      id: premierId + 2,
      action: 'APPROVED_BY_DIRECTEUR_EXPLOITATION',
      statut: 'approved_by_directeur_exploitation',
      le: fin.subtract(const Duration(days: 4)),
      acteur: thomas,
    ),
    EvenementDemo(
      id: premierId + 3,
      action: 'APPROVED_BY_RESPONSABLE_ETUDE',
      statut: 'approved_by_responsable_etude',
      le: fin.subtract(const Duration(days: 2)),
      acteur: nadia,
    ),
    EvenementDemo(
      id: premierId + 4,
      action: 'APPROVED_BY_SERVICE_GESTION',
      statut: 'approved_by_service_gestion',
      le: fin,
      acteur: elodie,
      commentaire: 'Validé.',
    ),
  ];
}
