import 'json.dart';

/// Rôle du module RC détenu par l'utilisateur.
///
/// `etape` suit les clés du CODE DG Flow (RP, DP, DE = Directeur d'Exploitation,
/// RE = Directeur d'Études, SG) ; `sigle` est celui affiché (RP, DP, DEX, DE, SG).
class RoleProfil {
  const RoleProfil({required this.id, required this.nom, required this.libelle, this.etape, this.sigle});

  factory RoleProfil.fromJson(Json j) => RoleProfil(
    id: asInt(j['id']),
    nom: asString(j['nom']),
    libelle: asString(j['libelle'], asString(j['nom'])),
    etape: asStringOrNull(j['etape']),
    sigle: asStringOrNull(j['sigle']),
  );

  final int id;
  final String nom;
  final String libelle;
  final String? etape;
  final String? sigle;

  /// Sigle affiché dans les pastilles (« DP »), ou l'initiale du libellé.
  String get monogramme => sigle ?? (libelle.isEmpty ? '?' : libelle.substring(0, 1).toUpperCase());

  Json toJson() => {'id': id, 'nom': nom, 'libelle': libelle, 'etape': etape, 'sigle': sigle};
}

class Profil {
  const Profil({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.roleActif,
    required this.roles,
    required this.lectureSeule,
    this.motifLectureSeule,
  });

  factory Profil.fromJson(Json j) => Profil(
    id: asInt(j['id']),
    nom: asString(j['nom']),
    prenom: asString(j['prenom']),
    email: asString(j['email']),
    roleActif: RoleProfil.fromJson(asJson(j['roleActif'])),
    roles: asList(j['roles'], RoleProfil.fromJson),
    lectureSeule: asBool(j['lectureSeule']),
    motifLectureSeule: asStringOrNull(j['motifLectureSeule']),
  );

  final int id;
  final String nom;
  final String prenom;
  final String email;
  final RoleProfil roleActif;
  final List<RoleProfil> roles;
  final bool lectureSeule;
  final String? motifLectureSeule;

  String get nomComplet => '$prenom $nom'.trim();

  String get initiales {
    final p = prenom.isNotEmpty ? prenom.substring(0, 1) : '';
    final n = nom.isNotEmpty ? nom.substring(0, 1) : '';
    final i = '$p$n'.toUpperCase();
    return i.isEmpty ? '?' : i;
  }

  bool get plusieursRoles => roles.length > 1;
}

/// Réponse de `/auth/login` et `/auth/microsoft`.
class ReponseConnexion {
  const ReponseConnexion({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.utilisateur,
  });

  factory ReponseConnexion.fromJson(Json j) => ReponseConnexion(
    accessToken: asString(j['accessToken']),
    refreshToken: asString(j['refreshToken']),
    expiresIn: asInt(j['expiresIn']),
    utilisateur: Profil.fromJson(asJson(j['utilisateur'])),
  );

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final Profil utilisateur;
}

/// Réponse de `/auth/refresh` (rotation du jeton de rafraîchissement).
class JetonsRafraichis {
  const JetonsRafraichis({required this.accessToken, required this.refreshToken, required this.expiresIn});

  factory JetonsRafraichis.fromJson(Json j) => JetonsRafraichis(
    accessToken: asString(j['accessToken']),
    refreshToken: asString(j['refreshToken']),
    expiresIn: asInt(j['expiresIn']),
  );

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
}

class SsoMicrosoft {
  const SsoMicrosoft({required this.tenantId, required this.clientId});

  final String tenantId;
  final String clientId;
}

/// `/meta` : version de l'API, version minimale de l'app, SSO disponible.
class Meta {
  const Meta({required this.api, required this.versionMinimaleApp, this.microsoft});

  factory Meta.fromJson(Json j) {
    final ms = asJsonOrNull(asJson(j['sso'])['microsoft']);
    return Meta(
      api: asString(j['api']),
      versionMinimaleApp: asString(j['versionMinimaleApp'], '0.0.0'),
      microsoft: ms == null || asString(ms['tenantId']).isEmpty || asString(ms['clientId']).isEmpty
          ? null
          : SsoMicrosoft(tenantId: asString(ms['tenantId']), clientId: asString(ms['clientId'])),
    );
  }

  final String api;
  final String versionMinimaleApp;
  final SsoMicrosoft? microsoft;
}

/// Session ouverte sur un appareil (`/me/sessions`).
class SessionAppareil {
  const SessionAppareil({
    required this.sid,
    required this.creeLe,
    required this.utiliseLe,
    required this.courante,
    this.appareil,
    this.plateforme,
  });

  factory SessionAppareil.fromJson(Json j) => SessionAppareil(
    sid: asString(j['sid']),
    appareil: asStringOrNull(j['appareil']),
    plateforme: asStringOrNull(j['plateforme']),
    creeLe: asDate(j['creeLe']),
    utiliseLe: asDate(j['utiliseLe']),
    courante: asBool(j['courante']),
  );

  final String sid;
  final String? appareil;
  final String? plateforme;
  final DateTime creeLe;
  final DateTime utiliseLe;
  final bool courante;
}
