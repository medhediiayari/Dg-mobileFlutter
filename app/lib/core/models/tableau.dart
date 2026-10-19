import 'json.dart';

/// Tableau chiffré d'un document : comparatif (RC), explicatif (avenant) ou absent.
sealed class Tableau {
  const Tableau();

  factory Tableau.fromJson(Json j) => switch (j['genre']) {
    'COMPARATIF' => TableauComparatif.fromJson(j),
    'EXPLICATIF' => TableauExplicatif.fromJson(j),
    _ => const TableauAbsent(),
  };
}

class TableauAbsent extends Tableau {
  const TableauAbsent();
}

class TotauxComparatif {
  const TotauxComparatif({
    required this.budgetEtude,
    required this.transfert,
    required this.etudeRecale,
    required this.objectif,
  });

  factory TotauxComparatif.fromJson(Json j) => TotauxComparatif(
    budgetEtude: asDouble(j['budgetEtude']),
    transfert: asDouble(j['transfert']),
    etudeRecale: asDouble(j['etudeRecale']),
    objectif: asDouble(j['objectif']),
  );

  final double budgetEtude;
  final double transfert;
  final double etudeRecale;
  final double objectif;
}

class OffreEntreprise {
  const OffreEntreprise({
    required this.id,
    required this.nom,
    required this.retenue,
    required this.total,
    required this.ecartBudget,
    required this.prixManquants,
  });

  factory OffreEntreprise.fromJson(Json j) => OffreEntreprise(
    id: asInt(j['id']),
    nom: asString(j['nom'], 'Entreprise'),
    retenue: asBool(j['retenue']),
    total: asDouble(j['total']),
    ecartBudget: asDouble(j['ecartBudget']),
    prixManquants: asInt(j['prixManquants']),
  );

  final int id;
  final String nom;
  final bool retenue;
  final double total;
  final double ecartBudget;
  final int prixManquants;
}

class PrixArticle {
  const PrixArticle({required this.entrepriseId, this.prixUnitaire, this.quantite, this.total});

  factory PrixArticle.fromJson(Json j) => PrixArticle(
    entrepriseId: asInt(j['entrepriseId']),
    prixUnitaire: asDoubleOrNull(j['prixUnitaire']),
    quantite: asDoubleOrNull(j['quantite']),
    total: asDoubleOrNull(j['total']),
  );

  final int entrepriseId;
  final double? prixUnitaire;
  final double? quantite;
  final double? total;
}

class ArticleComparatif {
  const ArticleComparatif({
    required this.id,
    required this.designation,
    required this.titre,
    required this.exclu,
    required this.transfere,
    required this.quantite,
    required this.puBudget,
    required this.ptBudget,
    required this.prix,
    this.observation,
    this.unite,
  });

  factory ArticleComparatif.fromJson(Json j) => ArticleComparatif(
    id: asInt(j['id']),
    designation: asString(j['designation']),
    titre: asBool(j['titre']),
    exclu: asBool(j['exclu']),
    transfere: asBool(j['transfere']),
    observation: asStringOrNull(j['observation']),
    quantite: asDouble(j['quantite']),
    unite: asStringOrNull(j['unite']),
    puBudget: asDouble(j['puBudget']),
    ptBudget: asDouble(j['ptBudget']),
    prix: asList(j['prix'], PrixArticle.fromJson),
  );

  final int id;
  final String designation;

  /// Ligne d'ouvrage (titre de groupe), sans prix.
  final bool titre;
  final bool exclu;
  final bool transfere;
  final String? observation;
  final double quantite;
  final String? unite;
  final double puBudget;
  final double ptBudget;
  final List<PrixArticle> prix;
}

class TableauComparatif extends Tableau {
  const TableauComparatif({
    required this.id,
    required this.nom,
    required this.numero,
    required this.statut,
    required this.totaux,
    required this.entreprises,
    required this.articles,
    this.codification,
    this.lot,
    this.justification,
  });

  factory TableauComparatif.fromJson(Json j) => TableauComparatif(
    id: asInt(j['id']),
    nom: asString(j['nom']),
    numero: asInt(j['numero'], 1),
    codification: asStringOrNull(j['codification']),
    lot: asStringOrNull(j['lot']),
    statut: asString(j['statut']),
    justification: asStringOrNull(j['justification']),
    totaux: TotauxComparatif.fromJson(asJson(j['totaux'])),
    entreprises: asList(j['entreprises'], OffreEntreprise.fromJson),
    articles: asList(j['articles'], ArticleComparatif.fromJson),
  );

  final int id;
  final String nom;
  final int numero;
  final String? codification;
  final String? lot;
  final String statut;
  final String? justification;
  final TotauxComparatif totaux;
  final List<OffreEntreprise> entreprises;
  final List<ArticleComparatif> articles;
}

class LigneExplicatif {
  const LigneExplicatif({
    required this.id,
    required this.designation,
    required this.isSousLigne,
    required this.fg,
    required this.margeClient,
    required this.margeNonClient,
    this.osNumero,
    this.numeroDevisClient,
    this.montantClient,
    this.montantStClient,
    this.provenanceBudget,
    this.montantBudgetTravaux,
    this.montantStNonClient,
  });

  factory LigneExplicatif.fromJson(Json j) => LigneExplicatif(
    id: asInt(j['id']),
    designation: asString(j['designation']),
    isSousLigne: asBool(j['isSousLigne']),
    osNumero: asStringOrNull(j['osNumero']),
    numeroDevisClient: asStringOrNull(j['numeroDevisClient']),
    montantClient: asDoubleOrNull(j['montantClient']),
    montantStClient: asDoubleOrNull(j['montantStClient']),
    provenanceBudget: asStringOrNull(j['provenanceBudget']),
    montantBudgetTravaux: asDoubleOrNull(j['montantBudgetTravaux']),
    montantStNonClient: asDoubleOrNull(j['montantStNonClient']),
    fg: asDouble(j['fg']),
    margeClient: asDouble(j['margeClient']),
    margeNonClient: asDouble(j['margeNonClient']),
  );

  final int id;
  final String designation;
  final bool isSousLigne;
  final String? osNumero;
  final String? numeroDevisClient;
  final double? montantClient;
  final double? montantStClient;
  final String? provenanceBudget;
  final double? montantBudgetTravaux;
  final double? montantStNonClient;
  final double fg;
  final double margeClient;
  final double margeNonClient;
}

class TotauxExplicatif {
  const TotauxExplicatif({
    required this.totalMontantClient,
    required this.totalMontantStClient,
    required this.totalFg,
    required this.totalBudgetTravaux,
    required this.totalMontantStNonClient,
    required this.montantAvenant,
    required this.marge,
    required this.budgetTravaux,
    required this.ecartSstObjectifTravaux,
  });

  factory TotauxExplicatif.fromJson(Json j) => TotauxExplicatif(
    totalMontantClient: asDouble(j['totalMontantClient']),
    totalMontantStClient: asDouble(j['totalMontantStClient']),
    totalFg: asDouble(j['totalFg']),
    totalBudgetTravaux: asDouble(j['totalBudgetTravaux']),
    totalMontantStNonClient: asDouble(j['totalMontantStNonClient']),
    montantAvenant: asDouble(j['montantAvenant']),
    marge: asDouble(j['marge']),
    budgetTravaux: asDouble(j['budgetTravaux']),
    ecartSstObjectifTravaux: asDouble(j['ecartSstObjectifTravaux']),
  );

  final double totalMontantClient;
  final double totalMontantStClient;
  final double totalFg;
  final double totalBudgetTravaux;
  final double totalMontantStNonClient;
  final double montantAvenant;
  final double marge;
  final double budgetTravaux;
  final double ecartSstObjectifTravaux;
}

class TableauExplicatif extends Tableau {
  const TableauExplicatif({
    required this.id,
    required this.statut,
    required this.cloture,
    required this.fgTaux,
    required this.lignes,
    required this.totaux,
    this.codification,
    this.commentaires,
  });

  factory TableauExplicatif.fromJson(Json j) => TableauExplicatif(
    id: asInt(j['id']),
    codification: asStringOrNull(j['codification']),
    statut: asString(j['statut']),
    cloture: asBool(j['cloture']),
    fgTaux: asDouble(j['fgTaux']),
    commentaires: asStringOrNull(j['commentaires']),
    lignes: asList(j['lignes'], LigneExplicatif.fromJson),
    totaux: TotauxExplicatif.fromJson(asJson(j['totaux'])),
  );

  final int id;
  final String? codification;
  final String statut;
  final bool cloture;

  /// Taux de frais généraux (0,05 = 5 %).
  final double fgTaux;
  final String? commentaires;
  final List<LigneExplicatif> lignes;
  final TotauxExplicatif totaux;
}
