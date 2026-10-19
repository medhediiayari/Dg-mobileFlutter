import 'commun.dart';
import 'json.dart';

/// Garde de consultation : « on ne valide pas ce qu'on n'a pas lu ».
class Consultation {
  const Consultation({
    required this.autorise,
    required this.documentOk,
    required this.tableauOk,
    required this.tableauRequis,
    required this.perimee,
    this.message,
    this.consulteLe,
    this.consulteTableauLe,
  });

  factory Consultation.fromJson(Json j) => Consultation(
    autorise: asBool(j['autorise']),
    documentOk: asBool(j['documentOk']),
    tableauOk: asBool(j['tableauOk']),
    tableauRequis: asBool(j['tableauRequis'], true),
    perimee: asBool(j['perimee']),
    message: asStringOrNull(j['message']),
    consulteLe: asDateOrNull(j['consulteLe']),
    consulteTableauLe: asDateOrNull(j['consulteTableauLe']),
  );

  final bool autorise;
  final bool documentOk;
  final bool tableauOk;
  final bool tableauRequis;
  final bool perimee;
  final String? message;
  final DateTime? consulteLe;
  final DateTime? consulteTableauLe;
}

class ProjetDetail {
  const ProjetDetail({
    required this.id,
    required this.ville,
    required this.typologie,
    required this.type,
    this.code,
    this.nom,
    this.maitreOuvrage,
  });

  factory ProjetDetail.fromJson(Json j) => ProjetDetail(
    id: asInt(j['id']),
    code: asStringOrNull(j['code']),
    nom: asStringOrNull(j['nom']),
    ville: asString(j['ville']),
    typologie: asString(j['typologie']),
    type: asString(j['type']),
    maitreOuvrage: asStringOrNull(j['maitreOuvrage']),
  );

  final int id;
  final String? code;
  final String? nom;
  final String ville;
  final String typologie;
  final String type;
  final String? maitreOuvrage;
}

class RcParent {
  const RcParent({required this.id, required this.reference});

  factory RcParent.fromJson(Json j) => RcParent(id: asInt(j['id']), reference: asString(j['reference']));

  final int id;
  final String reference;
}

class AvenantResume {
  const AvenantResume({
    required this.id,
    required this.reference,
    required this.statut,
    required this.libelle,
    required this.ton,
    this.numero,
  });

  factory AvenantResume.fromJson(Json j) => AvenantResume(
    id: asInt(j['id']),
    numero: asIntOrNull(j['numero']),
    reference: asString(j['reference']),
    statut: asString(j['statut'], 'draft'),
    libelle: asString(j['libelle']),
    ton: Ton.depuis(j['ton']),
  );

  final int id;
  final int? numero;
  final String reference;
  final String statut;
  final String libelle;
  final Ton ton;
}

class Identification {
  const Identification({
    required this.creeLe,
    required this.majLe,
    this.redacteur,
    this.creation,
    this.maj,
    this.corpsEtat,
    this.prestation,
    this.numeroLot,
    this.dateDebut,
    this.dateFin,
  });

  factory Identification.fromJson(Json j) => Identification(
    redacteur: asStringOrNull(j['redacteur']),
    creation: asStringOrNull(j['creation']),
    maj: asStringOrNull(j['maj']),
    corpsEtat: asStringOrNull(j['corpsEtat']),
    prestation: asStringOrNull(j['prestation']),
    numeroLot: asStringOrNull(j['numeroLot']),
    dateDebut: asStringOrNull(j['dateDebut']),
    dateFin: asStringOrNull(j['dateFin']),
    creeLe: asDate(j['creeLe']),
    majLe: asDate(j['majLe']),
  );

  final String? redacteur;
  final String? creation;
  final String? maj;
  final String? corpsEtat;
  final String? prestation;
  final String? numeroLot;

  /// Texte libre saisi sur le web (affiché tel quel).
  final String? dateDebut;

  /// Date ISO.
  final String? dateFin;
  final DateTime creeLe;
  final DateTime majLe;
}

class MontantsAvenant {
  const MontantsAvenant({
    required this.montantHt,
    required this.budgetTravaux,
    required this.marge,
    required this.ecart,
  });

  factory MontantsAvenant.fromJson(Json j) => MontantsAvenant(
    montantHt: asDouble(j['montantHt']),
    budgetTravaux: asDouble(j['budgetTravaux']),
    marge: asDouble(j['marge']),
    ecart: asDouble(j['ecart']),
  );

  final double montantHt;
  final double budgetTravaux;
  final double marge;
  final double ecart;
}

class Montants {
  const Montants({
    required this.montantDepuisTableauExplicatif,
    this.budgetPrestation,
    this.budgetEtude,
    this.transfertEtude,
    this.budgetEtudeRecale,
    this.objectifTravaux,
    this.transfertTravaux,
    this.objectifTravauxRecale,
    this.ecartsSstEtude,
    this.ecartsSstTravaux,
    this.montantRetenu,
    this.avenant,
  });

  factory Montants.fromJson(Json j) => Montants(
    budgetPrestation: asDoubleOrNull(j['budgetPrestation']),
    budgetEtude: asDoubleOrNull(j['budgetEtude']),
    transfertEtude: asDoubleOrNull(j['transfertEtude']),
    budgetEtudeRecale: asDoubleOrNull(j['budgetEtudeRecale']),
    objectifTravaux: asDoubleOrNull(j['objectifTravaux']),
    transfertTravaux: asDoubleOrNull(j['transfertTravaux']),
    objectifTravauxRecale: asDoubleOrNull(j['objectifTravauxRecale']),
    ecartsSstEtude: asDoubleOrNull(j['ecartsSstEtude']),
    ecartsSstTravaux: asDoubleOrNull(j['ecartsSstTravaux']),
    montantRetenu: asDoubleOrNull(j['montantRetenu']),
    montantDepuisTableauExplicatif: asBool(j['montantDepuisTableauExplicatif']),
    avenant: asJsonOrNull(j['avenant']) == null ? null : MontantsAvenant.fromJson(asJson(j['avenant'])),
  );

  final double? budgetPrestation;
  final double? budgetEtude;
  final double? transfertEtude;
  final double? budgetEtudeRecale;
  final double? objectifTravaux;
  final double? transfertTravaux;
  final double? objectifTravauxRecale;
  final double? ecartsSstEtude;
  final double? ecartsSstTravaux;
  final double? montantRetenu;
  final bool montantDepuisTableauExplicatif;
  final MontantsAvenant? avenant;
}

class Paiement {
  const Paiement({
    this.directPourcentage,
    this.directMontant,
    this.coredifPourcentage,
    this.coredifMontant,
    this.erreur,
    this.libelle,
  });

  factory Paiement.fromJson(Json j) => Paiement(
    directPourcentage: asDoubleOrNull(j['directPourcentage']),
    directMontant: asDoubleOrNull(j['directMontant']),
    coredifPourcentage: asDoubleOrNull(j['coredifPourcentage']),
    coredifMontant: asDoubleOrNull(j['coredifMontant']),
    erreur: asStringOrNull(j['erreur']),
    libelle: asStringOrNull(j['libelle']),
  );

  final double? directPourcentage;
  final double? directMontant;
  final double? coredifPourcentage;
  final double? coredifMontant;
  final String? erreur;
  final String? libelle;
}

class Conditions {
  const Conditions({
    required this.insertion,
    required this.prorata,
    required this.retenue5Rg,
    required this.retenue5BonneFin,
    required this.dc4Modificatif,
    this.nbreHeuresInsertion,
    this.pourcentageProrata,
  });

  factory Conditions.fromJson(Json j) => Conditions(
    insertion: asBool(j['insertion']),
    nbreHeuresInsertion: asDoubleOrNull(j['nbreHeuresInsertion']),
    prorata: asBool(j['prorata']),
    pourcentageProrata: asStringOrNull(j['pourcentageProrata']),
    retenue5Rg: asBool(j['retenue5Rg']),
    retenue5BonneFin: asBool(j['retenue5BonneFin']),
    dc4Modificatif: asBool(j['dc4Modificatif']),
  );

  final bool insertion;
  final double? nbreHeuresInsertion;
  final bool prorata;
  final String? pourcentageProrata;
  final bool retenue5Rg;
  final bool retenue5BonneFin;
  final bool dc4Modificatif;
}

class EntrepriseContact {
  const EntrepriseContact({this.chargeAffaire, this.email, this.telephone, this.sousTraitantRang2});

  factory EntrepriseContact.fromJson(Json j) => EntrepriseContact(
    chargeAffaire: asStringOrNull(j['chargeAffaire']),
    email: asStringOrNull(j['email']),
    telephone: asStringOrNull(j['telephone']),
    sousTraitantRang2: asStringOrNull(j['sousTraitantRang2']),
  );

  final String? chargeAffaire;
  final String? email;
  final String? telephone;
  final String? sousTraitantRang2;

  bool get aUnContact =>
      (chargeAffaire?.isNotEmpty ?? false) || (email?.isNotEmpty ?? false) || (telephone?.isNotEmpty ?? false);
}

class EntrepriseConsultee {
  const EntrepriseConsultee({
    required this.id,
    required this.nom,
    required this.retenue,
    this.montant,
    this.observations,
  });

  factory EntrepriseConsultee.fromJson(Json j) => EntrepriseConsultee(
    id: asInt(j['id']),
    nom: asString(j['nom'], 'Entreprise'),
    montant: asDoubleOrNull(j['montant']),
    observations: asStringOrNull(j['observations']),
    retenue: asBool(j['retenue']),
  );

  final int id;
  final String nom;
  final double? montant;
  final String? observations;
  final bool retenue;
}

class SignatureApposee {
  const SignatureApposee({required this.par, required this.type, required this.le});

  factory SignatureApposee.fromJson(Json j) =>
      SignatureApposee(par: asString(j['par']), type: asString(j['type']), le: asDate(j['le']));

  final String par;
  final String type;
  final DateTime le;
}

class MessageEntrant {
  const MessageEntrant({required this.le, required this.pieces, this.message, this.par});

  factory MessageEntrant.fromJson(Json j) => MessageEntrant(
    message: asStringOrNull(j['message']),
    par: asStringOrNull(j['par']),
    le: asDate(j['le']),
    pieces: asList(j['pieces'], PieceJointe.fromJson),
  );

  final String? message;
  final String? par;
  final DateTime le;
  final List<PieceJointe> pieces;
}

class Rejet {
  const Rejet({required this.le, required this.pieces, this.auteur, this.motif, this.par, this.vers});

  factory Rejet.fromJson(Json j) => Rejet(
    auteur: asStringOrNull(j['auteur']),
    motif: asStringOrNull(j['motif']),
    par: asStringOrNull(j['par']),
    le: asDate(j['le']),
    vers: asStringOrNull(j['vers']),
    pieces: asList(j['pieces'], PieceJointe.fromJson),
  );

  final String? auteur;
  final String? motif;
  final String? par;
  final DateTime le;
  final String? vers;
  final List<PieceJointe> pieces;
}

class ReponseInfo {
  const ReponseInfo({required this.le, required this.pieces, this.message, this.par});

  factory ReponseInfo.fromJson(Json j) => ReponseInfo(
    message: asStringOrNull(j['message']),
    par: asStringOrNull(j['par']),
    le: asDate(j['le']),
    pieces: asList(j['pieces'], PieceJointe.fromJson),
  );

  final String? message;
  final String? par;
  final DateTime le;
  final List<PieceJointe> pieces;
}

class DemandeInfo {
  const DemandeInfo({
    required this.le,
    required this.pieces,
    required this.pourMoi,
    this.message,
    this.par,
    this.vers,
    this.reponse,
  });

  factory DemandeInfo.fromJson(Json j) => DemandeInfo(
    message: asStringOrNull(j['message']),
    par: asStringOrNull(j['par']),
    vers: asStringOrNull(j['vers']),
    le: asDate(j['le']),
    pieces: asList(j['pieces'], PieceJointe.fromJson),
    reponse: asJsonOrNull(j['reponse']) == null ? null : ReponseInfo.fromJson(asJson(j['reponse'])),
    pourMoi: asBool(j['pourMoi']),
  );

  final String? message;
  final String? par;
  final String? vers;
  final DateTime le;
  final List<PieceJointe> pieces;
  final ReponseInfo? reponse;
  final bool pourMoi;
}

enum GenreTableau {
  comparatif,
  explicatif;

  static GenreTableau? depuis(Object? v) => switch (v) {
    'COMPARATIF' => GenreTableau.comparatif,
    'EXPLICATIF' => GenreTableau.explicatif,
    _ => null,
  };

  String get nom => this == GenreTableau.explicatif ? 'Tableau explicatif' : 'Tableau comparatif';
}

class TableauRef {
  const TableauRef({required this.genre, required this.id});

  final GenreTableau genre;
  final int id;
}

class EtapeLibelle {
  const EtapeLibelle({required this.sigle, required this.libelle});

  final String sigle;
  final String libelle;
}

/// Ce que l'utilisateur peut faire sur ce document, calculé par le serveur.
class ActionsDocument {
  const ActionsDocument({
    required this.peutApprouver,
    required this.peutRejeter,
    required this.rejetAvecDestinataire,
    required this.peutDemanderInfo,
    required this.peutRepondreInfo,
    required this.peutConvertirBc,
    required this.peutAnnulerBc,
    required this.signatureManquante,
    required this.destinatairesRenvoi,
    required this.destinatairesInfo,
    this.motif,
    this.etape,
    this.paiementBloquant,
    this.destinatairePropose,
  });

  factory ActionsDocument.fromJson(Json j) {
    final etape = asJsonOrNull(j['etape']);
    return ActionsDocument(
      peutApprouver: asBool(j['peutApprouver']),
      peutRejeter: asBool(j['peutRejeter']),
      rejetAvecDestinataire: asBool(j['rejetAvecDestinataire']),
      peutDemanderInfo: asBool(j['peutDemanderInfo']),
      peutRepondreInfo: asBool(j['peutRepondreInfo']),
      peutConvertirBc: asBool(j['peutConvertirBc']),
      peutAnnulerBc: asBool(j['peutAnnulerBc']),
      signatureManquante: asBool(j['signatureManquante']),
      motif: asStringOrNull(j['motif']),
      etape: etape == null ? null : EtapeLibelle(sigle: asString(etape['sigle']), libelle: asString(etape['libelle'])),
      paiementBloquant: asStringOrNull(j['paiementBloquant']),
      destinatairesRenvoi: asList(j['destinatairesRenvoi'], Destinataire.fromJson),
      destinatairesInfo: asList(j['destinatairesInfo'], Destinataire.fromJson),
      destinatairePropose: asIntOrNull(j['destinatairePropose']),
    );
  }

  final bool peutApprouver;
  final bool peutRejeter;
  final bool rejetAvecDestinataire;
  final bool peutDemanderInfo;
  final bool peutRepondreInfo;
  final bool peutConvertirBc;
  final bool peutAnnulerBc;
  final bool signatureManquante;
  final String? motif;
  final EtapeLibelle? etape;
  final String? paiementBloquant;
  final List<Destinataire> destinatairesRenvoi;
  final List<Destinataire> destinatairesInfo;
  final int? destinatairePropose;

  /// L'utilisateur tranche (approuver, rejeter ou convertir en BC).
  bool get decideur => peutApprouver || peutRejeter || peutConvertirBc;
}

/// Fiche complète d'un RC / avenant (`GET /rc/:rcId`).
class Detail {
  const Detail({
    required this.id,
    required this.type,
    required this.reference,
    required this.intitule,
    required this.version,
    required this.statut,
    required this.libelle,
    required this.ton,
    required this.estBc,
    required this.projet,
    required this.avenants,
    required this.identification,
    required this.montants,
    required this.paiement,
    required this.conditions,
    required this.entreprise,
    required this.entreprisesConsultees,
    required this.signatures,
    required this.nombreFichiers,
    required this.consultation,
    required this.actions,
    this.numeroAvenant,
    this.rcParent,
    this.commentaire,
    this.messageEntrant,
    this.rejet,
    this.demandeInfo,
    this.tableau,
  });

  factory Detail.fromJson(Json j) {
    final tableau = asJsonOrNull(j['tableau']);
    final genre = tableau == null ? null : GenreTableau.depuis(tableau['genre']);
    return Detail(
      id: asInt(j['id']),
      type: TypeDocument.depuis(j['type']),
      numeroAvenant: asIntOrNull(j['numeroAvenant']),
      reference: asString(j['reference']),
      intitule: asString(j['intitule']),
      version: asInt(j['version'], 1),
      statut: asString(j['statut'], 'draft'),
      libelle: asString(j['libelle']),
      ton: Ton.depuis(j['ton']),
      estBc: asBool(j['estBc']),
      projet: ProjetDetail.fromJson(asJson(j['projet'])),
      rcParent: asJsonOrNull(j['rcParent']) == null ? null : RcParent.fromJson(asJson(j['rcParent'])),
      avenants: asList(j['avenants'], AvenantResume.fromJson),
      identification: Identification.fromJson(asJson(j['identification'])),
      montants: Montants.fromJson(asJson(j['montants'])),
      paiement: Paiement.fromJson(asJson(j['paiement'])),
      conditions: Conditions.fromJson(asJson(j['conditions'])),
      entreprise: EntrepriseContact.fromJson(asJson(j['entreprise'])),
      entreprisesConsultees: asList(j['entreprisesConsultees'], EntrepriseConsultee.fromJson),
      commentaire: asStringOrNull(j['commentaire']),
      signatures: asList(j['signatures'], SignatureApposee.fromJson),
      messageEntrant: asJsonOrNull(j['messageEntrant']) == null
          ? null
          : MessageEntrant.fromJson(asJson(j['messageEntrant'])),
      rejet: asJsonOrNull(j['rejet']) == null ? null : Rejet.fromJson(asJson(j['rejet'])),
      demandeInfo: asJsonOrNull(j['demandeInfo']) == null ? null : DemandeInfo.fromJson(asJson(j['demandeInfo'])),
      tableau: genre == null ? null : TableauRef(genre: genre, id: asInt(tableau!['id'])),
      nombreFichiers: asInt(j['nombreFichiers']),
      consultation: Consultation.fromJson(asJson(j['consultation'])),
      actions: ActionsDocument.fromJson(asJson(j['actions'])),
    );
  }

  final int id;
  final TypeDocument type;
  final int? numeroAvenant;
  final String reference;
  final String intitule;
  final int version;
  final String statut;
  final String libelle;
  final Ton ton;
  final bool estBc;
  final ProjetDetail projet;
  final RcParent? rcParent;
  final List<AvenantResume> avenants;
  final Identification identification;
  final Montants montants;
  final Paiement paiement;
  final Conditions conditions;
  final EntrepriseContact entreprise;
  final List<EntrepriseConsultee> entreprisesConsultees;
  final String? commentaire;
  final List<SignatureApposee> signatures;
  final MessageEntrant? messageEntrant;
  final Rejet? rejet;
  final DemandeInfo? demandeInfo;
  final TableauRef? tableau;
  final int nombreFichiers;
  final Consultation consultation;
  final ActionsDocument actions;

  bool get estAvenant => type == TypeDocument.avenant;

  /// « RC » ou « Avenant 2 ».
  String get libelleType => estAvenant ? 'Avenant ${numeroAvenant ?? ''}'.trim() : 'RC';

  /// Nom du tableau chiffré associé.
  String get nomTableau => (tableau?.genre ?? (estAvenant ? GenreTableau.explicatif : GenreTableau.comparatif)).nom;

  /// Même fiche avec une nouvelle garde (lecture enregistrée, sans tout relire).
  Detail avecConsultation(Consultation c) => Detail(
    id: id,
    type: type,
    numeroAvenant: numeroAvenant,
    reference: reference,
    intitule: intitule,
    version: version,
    statut: statut,
    libelle: libelle,
    ton: ton,
    estBc: estBc,
    projet: projet,
    rcParent: rcParent,
    avenants: avenants,
    identification: identification,
    montants: montants,
    paiement: paiement,
    conditions: conditions,
    entreprise: entreprise,
    entreprisesConsultees: entreprisesConsultees,
    commentaire: commentaire,
    signatures: signatures,
    messageEntrant: messageEntrant,
    rejet: rejet,
    demandeInfo: demandeInfo,
    tableau: tableau,
    nombreFichiers: nombreFichiers,
    consultation: c,
    actions: actions,
  );
}
