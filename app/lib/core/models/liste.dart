import 'commun.dart';
import 'json.dart';

class ProjetResume {
  const ProjetResume({required this.id, required this.ville, this.code, this.nom});

  factory ProjetResume.fromJson(Json j) => ProjetResume(
    id: asInt(j['id']),
    code: asStringOrNull(j['code']),
    nom: asStringOrNull(j['nom']),
    ville: asString(j['ville']),
  );

  final int id;
  final String? code;
  final String? nom;
  final String ville;
}

class EntrepriseRetenue {
  const EntrepriseRetenue({this.nom, this.montant});

  factory EntrepriseRetenue.fromJson(Json j) =>
      EntrepriseRetenue(nom: asStringOrNull(j['nom']), montant: asDoubleOrNull(j['montant']));

  final String? nom;
  final double? montant;
}

class DernierEvenement {
  const DernierEvenement({required this.libelle, required this.le, this.par});

  factory DernierEvenement.fromJson(Json j) =>
      DernierEvenement(libelle: asString(j['libelle']), par: asStringOrNull(j['par']), le: asDate(j['le']));

  final String libelle;
  final String? par;
  final DateTime le;
}

/// Carte d'un RC / avenant dans les listes « À traiter » et « Suivi ».
class ElementListe {
  const ElementListe({
    required this.id,
    required this.type,
    required this.reference,
    required this.intitule,
    required this.projet,
    required this.statut,
    required this.libelle,
    required this.ton,
    required this.aTraiter,
    required this.infoPourMoi,
    required this.estBc,
    required this.majLe,
    this.numeroAvenant,
    this.bucket,
    this.entreprise,
    this.dernierEvenement,
    this.consultationRequise,
  });

  factory ElementListe.fromJson(Json j) => ElementListe(
    id: asInt(j['id']),
    type: TypeDocument.depuis(j['type']),
    numeroAvenant: asIntOrNull(j['numeroAvenant']),
    reference: asString(j['reference']),
    intitule: asString(j['intitule']),
    projet: ProjetResume.fromJson(asJson(j['projet'])),
    statut: asString(j['statut'], 'draft'),
    libelle: asString(j['libelle']),
    ton: Ton.depuis(j['ton']),
    bucket: Bucket.depuis(j['bucket']),
    entreprise: asJsonOrNull(j['entreprise']) == null ? null : EntrepriseRetenue.fromJson(asJson(j['entreprise'])),
    dernierEvenement: asJsonOrNull(j['dernierEvenement']) == null
        ? null
        : DernierEvenement.fromJson(asJson(j['dernierEvenement'])),
    aTraiter: asBool(j['aTraiter']),
    infoPourMoi: asBool(j['infoPourMoi']),
    estBc: asBool(j['estBc']),
    consultationRequise: asStringOrNull(j['consultationRequise']),
    majLe: asDate(j['majLe']),
  );

  final int id;
  final TypeDocument type;
  final int? numeroAvenant;
  final String reference;
  final String intitule;
  final ProjetResume projet;
  final String statut;
  final String libelle;
  final Ton ton;
  final Bucket? bucket;
  final EntrepriseRetenue? entreprise;
  final DernierEvenement? dernierEvenement;
  final bool aTraiter;
  final bool infoPourMoi;
  final bool estBc;
  final String? consultationRequise;
  final DateTime majLe;
}

class Compteurs {
  const Compteurs({required this.parBucket, required this.aTraiter, required this.infoPourMoi});

  factory Compteurs.fromJson(Json j) => Compteurs(
    parBucket: {for (final b in Bucket.values) b: asInt(j[b.name])},
    aTraiter: asInt(j['aTraiter']),
    infoPourMoi: asInt(j['infoPourMoi']),
  );

  static const vide = Compteurs(parBucket: {}, aTraiter: 0, infoPourMoi: 0);

  final Map<Bucket, int> parBucket;
  final int aTraiter;
  final int infoPourMoi;

  int operator [](Bucket b) => parBucket[b] ?? 0;
}

/// Page de `/rc` : éléments + compteurs du tableau de bord.
class ReponseListe {
  const ReponseListe({
    required this.elements,
    required this.page,
    required this.total,
    required this.aSuivre,
    required this.compteurs,
    required this.libellesBuckets,
    required this.enAttenteReception,
  });

  factory ReponseListe.fromJson(Json j) {
    final libelles = asJson(j['libellesBuckets']);
    return ReponseListe(
      elements: asList(j['elements'], ElementListe.fromJson),
      page: asInt(j['page'], 1),
      total: asInt(j['total']),
      aSuivre: asBool(j['aSuivre']),
      compteurs: Compteurs.fromJson(asJson(j['compteurs'])),
      libellesBuckets: {for (final b in Bucket.values) b: asString(libelles[b.name], b.libelleParDefaut)},
      enAttenteReception: asInt(j['enAttenteReception']),
    );
  }

  final List<ElementListe> elements;
  final int page;
  final int total;
  final bool aSuivre;
  final Compteurs compteurs;
  final Map<Bucket, String> libellesBuckets;
  final int enAttenteReception;
}

/// Filtres de `/rc` (vue, état, type, recherche).
class FiltresListe {
  const FiltresListe({required this.vue, this.bucket, this.type, this.q = ''});

  static const aTraiter = FiltresListe(vue: 'a-traiter');

  final String vue;
  final Bucket? bucket;
  final TypeDocument? type;
  final String q;

  Map<String, String> parametres({required int page, required int limite}) => {
    'vue': vue,
    'page': '$page',
    'limite': '$limite',
    if (bucket != null) 'bucket': bucket!.name,
    if (type != null) 'type': type!.code,
    if (q.trim().isNotEmpty) 'q': q.trim(),
  };

  @override
  bool operator ==(Object other) =>
      other is FiltresListe && other.vue == vue && other.bucket == bucket && other.type == type && other.q == q;

  @override
  int get hashCode => Object.hash(vue, bucket, type, q);
}
