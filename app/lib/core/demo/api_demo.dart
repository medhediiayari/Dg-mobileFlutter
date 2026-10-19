import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../api/api_exception.dart';
import '../api/api_http.dart' show fichierTelechargement;
import '../api/dgflow_api.dart';
import '../models/models.dart';
import 'monde_demo.dart';
import 'regles_demo.dart';

/// API de démonstration, en mémoire : mêmes routes, mêmes règles principales
/// (garde de consultation, paiement, signature, statuts par étape), même JSON
/// que l'API réelle — chaque réponse est construite en `Map` puis lue par les
/// mêmes `fromJson` que le mode réel.
class ApiDemo implements DgFlowApi {
  ApiDemo({DateTime? maintenant, this.latence = const Duration(milliseconds: 380), this.aUneSignature = true})
    : _debut = maintenant ?? DateTime.now(),
      _chrono = Stopwatch()..start() {
    monde = MondeDemo(_debut);
  }

  late final MondeDemo monde;
  final DateTime _debut;
  final Stopwatch _chrono;

  /// Délai simulé de chaque appel (squelettes visibles en démonstration).
  final Duration latence;

  /// Signature présente au profil (sans elle, approbation impossible).
  bool aUneSignature;

  bool _connecte = false;
  int _roleActifId = 3;
  int _prochainId = 9000;

  @override
  set surSessionExpiree(void Function()? rappel) {}

  DateTime get _maintenant => _debut.add(_chrono.elapsed);

  Future<T> _repondre<T>(T Function() calcul) async {
    if (latence > Duration.zero) await Future<void>.delayed(latence);
    if (!_connecte) throw const ApiException(401, 'Session expirée, reconnectez-vous', 'TOKEN_INVALID');
    return calcul();
  }

  Json get _roleActif => rolesDemo.firstWhere((r) => r['id'] == _roleActifId);
  String? get _etape => _roleActif['etape'] as String?;
  String get _nomRole => _roleActif['nom'] as String;
  PersonneDemo get _moi => PersonneDemo(moiDemo.id, moiDemo.prenom, moiDemo.nom, _nomRole);

  static String _iso(DateTime d) => d.toUtc().toIso8601String();

  // ─── Session ────────────────────────────────────────────────────────────

  @override
  Future<Meta> meta() async {
    if (latence > Duration.zero) await Future<void>.delayed(latence);
    return Meta.fromJson({
      'api': '1.0.0-demo',
      'versionMinimaleApp': '1.0.0',
      'sso': {'microsoft': null},
    });
  }

  @override
  Future<bool> restaurerSession() async => _connecte;

  Json _profilJson() {
    final etape = _etape;
    final motif = etape == null
        ? 'Votre rôle consulte le suivi des RC sans intervenir dans le circuit de validation.'
        : etape == 'RP'
        ? 'La saisie et l’envoi des RC se font sur DG Flow web. Ici : suivi du parcours et réponses aux demandes d’information.'
        : null;
    return {
      'id': moiDemo.id,
      'nom': moiDemo.nom,
      'prenom': moiDemo.prenom,
      'email': 'camille.lefevre@dggroup.fr',
      'roleActif': _roleActif,
      'roles': rolesDemo,
      'lectureSeule': motif != null,
      'motifLectureSeule': motif,
    };
  }

  @override
  Future<ReponseConnexion> connexion({
    required String email,
    required String motDePasse,
    String? appareil,
    String? plateforme,
  }) async {
    if (latence > Duration.zero) await Future<void>.delayed(latence * 2);
    if (!email.contains('@') || motDePasse.isEmpty) {
      throw const ApiException(401, 'Identifiants incorrects', 'INVALID_CREDENTIALS');
    }
    _connecte = true;
    return ReponseConnexion.fromJson({
      'accessToken': 'demo-acces',
      'refreshToken': 'demo-rafraichissement-0000000000000000000000000000000000',
      'expiresIn': 900,
      'utilisateur': _profilJson(),
    });
  }

  @override
  Future<ReponseConnexion> connexionMicrosoft({required String accessToken, String? appareil, String? plateforme}) =>
      Future.error(const ApiException(404, 'Connexion Microsoft non configurée sur ce serveur', 'SSO_DISABLED'));

  @override
  Future<void> deconnexion() async => _connecte = false;

  @override
  Future<Profil> moi() => _repondre(() => Profil.fromJson(_profilJson()));

  @override
  Future<Profil> changerRole(int roleId) => _repondre(() {
    if (!rolesDemo.any((r) => r['id'] == roleId)) {
      throw const ApiException(403, "Ce rôle ne vous est pas attribué ou n'ouvre pas le module RC", 'ROLE_NOT_HELD');
    }
    _roleActifId = roleId;
    return Profil.fromJson(_profilJson());
  });

  @override
  Future<List<SessionAppareil>> sessions() => _repondre(() => asList(monde.sessions, SessionAppareil.fromJson));

  @override
  Future<void> revoquerSession(String sid) =>
      _repondre(() => monde.sessions.removeWhere((s) => s['sid'] == sid && s['courante'] != true));

  @override
  Future<void> enregistrerAppareil({
    required String installationId,
    required String jeton,
    required String plateforme,
  }) => _repondre(() {});

  @override
  Future<void> supprimerAppareil(String installationId) => _repondre(() {});

  // ─── Règles ─────────────────────────────────────────────────────────────

  DocDemo _doc(int rcId) {
    final d = monde.docs[rcId];
    if (d == null || !_visible(d)) throw const ApiException(404, 'RC introuvable', 'RC_NOT_FOUND');
    return d;
  }

  /// Demande d'information ouverte adressée à l'utilisateur.
  EvenementDemo? _demandePourMoi(DocDemo d) {
    final demande = d.evenements.lastWhereOrNull((e) => e.action.startsWith('INFO_REQUEST_BY_'));
    if (demande == null || demande.cible?.id != moiDemo.id) return null;
    final repondue = d.evenements.any(
      (e) => e.action.startsWith('INFO_RESPONSE_BY_') && e.acteur.id == moiDemo.id && e.le.isAfter(demande.le),
    );
    return repondue ? null : demande;
  }

  bool _visible(DocDemo d) {
    final s = d.statut;
    final info = _demandePourMoi(d) != null;
    return switch (_etape) {
      'DE' => info || !(s == 'draft' || s == 'approved_by_responsable_projet' || s == 'rejected_by_directeur_projet'),
      'RE' =>
        info ||
            s == 'approved_by_directeur_exploitation' ||
            s == 'approved_by_responsable_etude' ||
            s == 'approved_by_service_gestion' ||
            s.startsWith('rejected_by_responsable_etude') ||
            s.startsWith('rejected_by_service_gestion'),
      'SG' =>
        info ||
            s == 'approved_by_responsable_etude' ||
            s == 'approved_by_service_gestion' ||
            s.startsWith('rejected_by_service_gestion'),
      _ => true,
    };
  }

  ({bool autorise, bool documentOk, bool tableauOk, bool tableauRequis, bool perimee, String? message}) _garde(
    DocDemo d, [
    String action = 'approuver',
  ]) {
    final dernier = d.evenements.isEmpty ? null : d.evenements.last.le;
    final consulte = d.consulteLe;
    final documentOk = consulte != null && (dernier == null || !consulte.isBefore(dernier));
    final perimee = consulte != null && dernier != null && consulte.isBefore(dernier);
    final requis = d.tableau != null;
    final tableauOk = !requis || d.consulteTableauLe != null;
    final avenant = d.type == 'AVENANT';
    final message = !documentOk
        ? messageGardeConsultation(avenant: avenant, perimee: perimee, action: action)
        : !tableauOk
        ? messageGardeTableau(avenant: avenant, action: action)
        : null;
    return (
      autorise: documentOk && tableauOk,
      documentOk: documentOk,
      tableauOk: tableauOk,
      tableauRequis: requis,
      perimee: perimee,
      message: message,
    );
  }

  Json _gardeJson(DocDemo d) {
    final g = _garde(d);
    return {
      'autorise': g.autorise,
      'documentOk': g.documentOk,
      'tableauOk': g.tableauOk,
      'tableauRequis': g.tableauRequis,
      'perimee': g.perimee,
      'message': g.message,
      'consulteLe': d.consulteLe == null ? null : _iso(d.consulteLe!),
      'consulteTableauLe': d.consulteTableauLe == null ? null : _iso(d.consulteTableauLe!),
    };
  }

  bool _aMonEtape(DocDemo d) => statutsDecision[_etape]?.contains(d.statut) ?? false;

  Json _capacites(DocDemo d) {
    final etape = _etape;
    final repondre = _demandePourMoi(d) != null;
    final base = <String, dynamic>{
      'peutApprouver': false,
      'peutRejeter': false,
      'rejetAvecDestinataire': etape == 'RE' || etape == 'SG',
      'peutDemanderInfo': false,
      'peutRepondreInfo': repondre,
      'peutConvertirBc': false,
      'peutAnnulerBc': false,
      'signatureManquante': false,
      'motif': null,
    };
    if (!statutsDecision.containsKey(etape)) {
      return {...base, 'motif': repondre ? null : 'Consultation seule pour votre rôle.'};
    }
    final aMonEtape = _aMonEtape(d);
    final approuver = aMonEtape && !(etape == 'SG' && d.estBc);
    final convertir = etape == 'SG' && aMonEtape && !d.estBc;
    final annuler = etape == 'SG' && aMonEtape && d.estBc;
    final motif = !approuver && !aMonEtape && !repondre && !annuler
        ? "Ce document n'est pas en attente de votre décision."
        : null;
    return {
      ...base,
      'peutApprouver': approuver,
      'peutRejeter': aMonEtape,
      'peutDemanderInfo': aMonEtape,
      'peutConvertirBc': convertir,
      'peutAnnulerBc': annuler,
      'signatureManquante': (approuver || convertir) && !aUneSignature,
      'motif': motif,
    };
  }

  List<Json> _destinataires(DocDemo d) {
    final vus = <int>{};
    final liste = <Json>[];
    for (final p in [d.createur, moiDemo, thomas, nadia]) {
      if (vus.add(p.id)) liste.add({'id': p.id, 'nom': p.nomComplet, 'role': p.role});
    }
    return liste;
  }

  int? _precedent(DocDemo d) => d.evenements
      .lastWhereOrNull((e) => e.action.startsWith('APPROVED_BY_') && e.action != 'APPROVED_BY_SERVICE_GESTION')
      ?.acteur
      .id;

  List<Json> _piecesDe(EvenementDemo? e, String categorie) =>
      e == null ? const [] : e.pieces.where((p) => p['categorie'] == categorie).toList();

  // ─── Lecture ────────────────────────────────────────────────────────────

  String _reference(DocDemo d) => d.codification ?? '${d.type == 'AVENANT' ? 'AV' : 'RC'}-${d.id}';

  Json _elementJson(DocDemo d) {
    final statut = d.statut;
    final info = _demandePourMoi(d) != null;
    final aTraiter = info || _aMonEtape(d);
    final retenue = (d.fiche['entreprisesConsultees'] as List? ?? const []).cast<Json>().firstWhereOrNull(
      (e) => e['retenue'] == true,
    );
    final dernier = d.evenements.isEmpty ? null : d.evenements.last;
    final decideur = statutsDecision.containsKey(_etape);
    final g = _garde(d);
    final p = presentationStatut(statut);
    return {
      'id': d.id,
      'type': d.type,
      'numeroAvenant': d.numeroAvenant,
      'reference': _reference(d),
      'intitule': d.intitule,
      'projet': {'id': d.projet.id, 'code': d.projet.code, 'nom': d.projet.nom, 'ville': d.projet.ville},
      'statut': statut,
      'libelle': p.libelle,
      'ton': p.ton,
      'bucket': bucketDuStatut(_etape, statut),
      'entreprise': retenue == null ? null : {'nom': retenue['nom'], 'montant': retenue['montant']},
      'dernierEvenement': dernier == null
          ? null
          : {
              'libelle': libelleAction(dernier.action)?.etape ?? dernier.action,
              'par': dernier.acteur.nomComplet,
              'le': _iso(dernier.le),
            },
      'aTraiter': aTraiter,
      'infoPourMoi': info,
      'estBc': d.estBc,
      'consultationRequise': decideur && aTraiter && !g.autorise ? g.message : null,
      'majLe': _iso(d.majLe ?? d.derniereActivite),
    };
  }

  Json listeJson(FiltresListe f, {int page = 1, int limite = 25}) {
    final jetons = f.q.trim().toLowerCase().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    bool correspond(DocDemo d) {
      if (jetons.isEmpty) return true;
      final texte = [
        d.codification,
        d.intitule,
        d.projet.code,
        d.projet.nom,
        d.projet.ville,
        ...(d.fiche['entreprisesConsultees'] as List? ?? const [])
            .cast<Json>()
            .where((e) => e['retenue'] == true)
            .map((e) => e['nom']),
      ].whereType<String>().join(' ').toLowerCase();
      return jetons.every(texte.contains);
    }

    final docs =
        monde.docs.values
            .where((d) => f.type == null || d.type == f.type!.code)
            .where(correspond)
            .where(_visible)
            .toList()
          ..sort((a, b) => b.derniereActivite.compareTo(a.derniereActivite));

    final compteurs = <String, int>{
      'toReceive': 0,
      'pending': 0,
      'approved': 0,
      'rejected': 0,
      'aTraiter': 0,
      'infoPourMoi': 0,
    };
    for (final d in docs) {
      final b = bucketDuStatut(_etape, d.statut);
      if (b != null) compteurs[b] = compteurs[b]! + 1;
      final info = _demandePourMoi(d) != null;
      if (info || _aMonEtape(d)) compteurs['aTraiter'] = compteurs['aTraiter']! + 1;
      if (info) compteurs['infoPourMoi'] = compteurs['infoPourMoi']! + 1;
    }
    final retenus = f.vue == 'a-traiter'
        ? docs.where((d) => _demandePourMoi(d) != null || _aMonEtape(d)).toList()
        : f.bucket != null
        ? docs.where((d) => bucketDuStatut(_etape, d.statut) == f.bucket!.name).toList()
        : docs;
    final debut = (page - 1) * limite;
    final pageDocs = retenus.skip(debut).take(limite).toList();
    return {
      'elements': pageDocs.map(_elementJson).toList(),
      'page': page,
      'total': retenus.length,
      'aSuivre': page * limite < retenus.length,
      'compteurs': compteurs,
      'libellesBuckets': libellesBucket,
      'enAttenteReception': _etape == 'DP' ? 1 : 0,
    };
  }

  @override
  Future<ReponseListe> liste(FiltresListe filtres, {int page = 1, int limite = 25}) =>
      _repondre(() => ReponseListe.fromJson(listeJson(filtres, page: page, limite: limite)));

  Json detailJson(int rcId) {
    final d = _doc(rcId);
    final f = d.fiche;
    final statut = d.statut;
    final p = presentationStatut(statut);
    final evts = d.evenements;
    final predecesseurs = actionsPredecesseur(_nomRole);
    final entrant = evts.lastWhereOrNull((e) => predecesseurs.contains(e.action));
    final dernier = evts.isEmpty ? null : evts.last;
    final rejete = statut.startsWith('rejected');
    final demande = evts.lastWhereOrNull((e) => e.action.startsWith('INFO_REQUEST_BY_'));
    final reponse = demande == null
        ? null
        : evts.lastWhereOrNull(
            (e) =>
                e.action.startsWith('INFO_RESPONSE_BY_') &&
                e.cible?.id == demande.acteur.id &&
                e.le.isAfter(demande.le),
          );
    final capacites = _capacites(d);
    final destinataires = _destinataires(d);
    final etape = _etape;
    final parent = d.parentId == null ? null : monde.docs[d.parentId];
    final avenants = monde.docs.values.where((a) => a.parentId == d.id).toList()
      ..sort((a, b) => (a.numeroAvenant ?? 0).compareTo(b.numeroAvenant ?? 0));
    final paiement = asJson(f['paiement']);
    final tableau = d.tableau;

    return {
      'id': d.id,
      'type': d.type,
      'numeroAvenant': d.numeroAvenant,
      'reference': _reference(d),
      'intitule': d.intitule,
      'version': d.version,
      'statut': statut,
      'libelle': p.libelle,
      'ton': p.ton,
      'estBc': d.estBc,
      'projet': {
        'id': d.projet.id,
        'code': d.projet.code,
        'nom': d.projet.nom,
        'ville': d.projet.ville,
        'typologie': d.projet.typologie,
        'type': d.projet.type,
        'maitreOuvrage': d.projet.maitreOuvrage,
      },
      'rcParent': parent == null ? null : {'id': parent.id, 'reference': _reference(parent)},
      'avenants': [
        for (final a in avenants)
          {
            'id': a.id,
            'numero': a.numeroAvenant,
            'reference': a.codification ?? 'Avenant ${a.numeroAvenant ?? ''}'.trim(),
            'statut': a.statut,
            'libelle': presentationStatut(a.statut).libelle,
            'ton': presentationStatut(a.statut).ton,
          },
      ],
      'identification': {
        'redacteur': d.createur.nomComplet,
        'creation': null,
        'maj': null,
        'corpsEtat': f['corpsEtat'],
        'prestation': f['prestation'],
        'numeroLot': f['numeroLot'],
        'dateDebut': f['dateDebut'],
        'dateFin': f['dateFin'],
        'creeLe': _iso(d.creeLe),
        'majLe': _iso(d.majLe ?? d.derniereActivite),
      },
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
        'montantRetenu': null,
        'montantDepuisTableauExplicatif': false,
        'avenant': null,
        ...asJson(f['montants']),
      },
      'paiement': {
        'directPourcentage': paiement['directPourcentage'],
        'directMontant': paiement['directMontant'],
        'coredifPourcentage': paiement['coredifPourcentage'],
        'coredifMontant': paiement['coredifMontant'],
        'erreur': d.erreurPaiement,
        'libelle': paiement['libelle'],
      },
      'conditions': {
        'insertion': false,
        'nbreHeuresInsertion': null,
        'prorata': false,
        'pourcentageProrata': null,
        'retenue5Rg': false,
        'retenue5BonneFin': false,
        'dc4Modificatif': false,
        ...asJson(f['conditions']),
      },
      'entreprise': {
        'chargeAffaire': null,
        'email': null,
        'telephone': null,
        'sousTraitantRang2': null,
        ...asJson(f['entreprise']),
      },
      'entreprisesConsultees': f['entreprisesConsultees'] ?? const <Json>[],
      'commentaire': f['commentaire'],
      'signatures': d.signatures,
      'messageEntrant': entrant == null
          ? null
          : {
              'message': entrant.commentaire,
              'par': entrant.acteur.nomComplet,
              'le': _iso(entrant.le),
              'pieces': _piecesDe(entrant, 'approval'),
            },
      'rejet': rejete && dernier != null
          ? {
              'auteur': auteurRejet(statut),
              'motif': dernier.commentaire,
              'par': dernier.acteur.nomComplet,
              'le': _iso(dernier.le),
              'vers': dernier.cible?.nomComplet,
              'pieces': _piecesDe(dernier, 'rejection'),
            }
          : null,
      'demandeInfo': demande == null
          ? null
          : {
              'message': demande.commentaire,
              'par': demande.acteur.nomComplet,
              'vers': demande.cible?.nomComplet,
              'le': _iso(demande.le),
              'pieces': _piecesDe(demande, 'info_request'),
              'reponse': reponse == null
                  ? null
                  : {
                      'message': reponse.commentaire,
                      'par': reponse.acteur.nomComplet,
                      'le': _iso(reponse.le),
                      'pieces': _piecesDe(reponse, 'info_response'),
                    },
              'pourMoi': _demandePourMoi(d) != null,
            },
      'tableau': tableau == null ? null : {'genre': tableau['genre'], 'id': tableau['id']},
      'nombreFichiers': d.fichiers.length,
      'consultation': _gardeJson(d),
      'actions': {
        ...capacites,
        'etape': switch (etape) {
          'DP' => {'sigle': 'DP', 'libelle': 'Directeur Projet'},
          'DE' => {'sigle': 'DEX', 'libelle': "Directeur d'Exploitation"},
          'RE' => {'sigle': 'DE', 'libelle': "Directeur d'Études"},
          'SG' => {'sigle': 'SG', 'libelle': 'Service Gestion'},
          'RP' => {'sigle': 'RP', 'libelle': 'Responsable de Projet'},
          _ => null,
        },
        'paiementBloquant': d.erreurPaiement,
        'destinatairesRenvoi': capacites['peutRejeter'] == true && (etape == 'RE' || etape == 'SG')
            ? (etape == 'SG'
                  ? destinataires
                  : destinataires.where((x) => !(x['role'] as String).contains('Etude')).toList())
            : const <Json>[],
        'destinatairesInfo': capacites['peutDemanderInfo'] == true
            ? destinataires.where((x) => x['id'] != moiDemo.id).toList()
            : const <Json>[],
        'destinatairePropose': _precedent(d),
      },
    };
  }

  @override
  Future<Detail> detail(int rcId) => _repondre(() => Detail.fromJson(detailJson(rcId)));

  Json parcoursJson(int rcId) {
    final d = _doc(rcId);
    final etapes = <Json>[
      {
        'id': null,
        'etape': 'Création du document',
        'etat': 'completed',
        'le': _iso(d.creeLe),
        'par': d.createur.nomComplet,
        'motif': null,
        'message': null,
        'vers': null,
        'automatique': false,
        'pieces': const <Json>[],
      },
    ];
    for (final e in d.evenements) {
      final l = libelleAction(e.action);
      if (l == null) continue;
      final infoOuNote = l.etat == 'info' || l.etat == 'note';
      etapes.add({
        'id': e.id,
        'etape': l.etape,
        'etat': l.etat,
        'le': _iso(e.le),
        'par': e.acteur.nomComplet,
        'motif': l.etat == 'rejected' ? e.commentaire : null,
        'message': infoOuNote || l.etat == 'completed' ? e.commentaire : null,
        'vers': e.cible?.nomComplet,
        'automatique': false,
        'pieces': e.pieces,
      });
    }
    final statut = d.statut;
    final attente = enAttente[statut];
    if (attente != null) {
      etapes.add(_etapeFinale(attente, 'current'));
    } else if (statut == 'approved_by_service_gestion') {
      etapes.add(_etapeFinale('Document finalisé', 'completed'));
    }
    return {'statut': statut, 'etapes': etapes};
  }

  Json _etapeFinale(String libelle, String etat) => {
    'id': null,
    'etape': libelle,
    'etat': etat,
    'le': null,
    'par': null,
    'motif': null,
    'message': null,
    'vers': null,
    'automatique': false,
    'pieces': const <Json>[],
  };

  @override
  Future<Parcours> parcours(int rcId) => _repondre(() => Parcours.fromJson(parcoursJson(rcId)));

  @override
  Future<Tableau> tableau(int rcId) => _repondre(() => Tableau.fromJson(_doc(rcId).tableau ?? const {'genre': null}));

  @override
  Future<Consultation> enregistrerConsultation(int rcId, TypeConsultation type) => _repondre(() {
    final d = _doc(rcId);
    if (type == TypeConsultation.document) {
      d.consulteLe = _maintenant;
    } else {
      d.consulteTableauLe = _maintenant;
    }
    return Consultation.fromJson(_gardeJson(d));
  });

  // ─── Décisions ──────────────────────────────────────────────────────────

  void _exigerDecision(DocDemo d, String action) {
    if (!statutsDecision.containsKey(_etape)) {
      throw const ApiException(403, 'Votre rôle ne participe pas à la validation des RC', 'ROLE_NOT_DECIDER');
    }
    if (!_aMonEtape(d)) {
      throw ApiException(
        400,
        "Ce document n'est pas en attente de votre décision (statut actuel : ${d.statut})",
        'WRONG_STATUS',
        {'currentStatus': d.statut},
      );
    }
    final g = _garde(d, action);
    if (!g.autorise) {
      throw ApiException(
        409,
        g.message ?? 'Consultez le document avant de décider.',
        g.perimee
            ? 'CONSULTATION_PERIMEE'
            : !g.documentOk
            ? 'CONSULTATION_REQUISE'
            : 'CONSULTATION_TABLEAU_REQUISE',
      );
    }
  }

  void _exigerApprobation(DocDemo d) {
    final erreur = d.erreurPaiement;
    if (erreur != null) {
      throw ApiException(
        400,
        '$erreur. Le paiement doit être corrigé dans le formulaire (renvoyez le document pour correction si vous ne pouvez pas le modifier).',
        'PAIEMENT_INCOHERENT',
        {'message': erreur},
      );
    }
    if (!aUneSignature) {
      throw const ApiException(
        400,
        'Ajoutez votre signature dans votre profil DG Flow (web) avant de pouvoir approuver.',
        'SIGNATURE_MANQUANTE',
      );
    }
  }

  EvenementDemo _ajouter(DocDemo d, String action, String statut, {String? commentaire, PersonneDemo? cible}) {
    final e = EvenementDemo(
      id: ++_prochainId,
      action: action,
      statut: statut,
      le: _maintenant,
      acteur: _moi,
      cible: cible,
      commentaire: commentaire,
    );
    d.evenements.add(e);
    d.majLe = e.le;
    return e;
  }

  Json _resultat(String message, String statut, int? evenementId, {bool? estBc}) => {
    'succes': true,
    'message': message,
    'statut': statut,
    'evenementId': evenementId,
    'estBc': ?estBc,
  };

  static const Map<String, (String, String)> _approbations = {
    'DP': ('APPROVED_BY_DIRECTEUR_PROJET', 'approved_by_directeur_projet'),
    'DE': ('APPROVED_BY_DIRECTEUR_EXPLOITATION', 'approved_by_directeur_exploitation'),
    'RE': ('APPROVED_BY_RESPONSABLE_ETUDE', 'approved_by_responsable_etude'),
    'SG': ('APPROVED_BY_SERVICE_GESTION', 'approved_by_service_gestion'),
  };

  String get _sigle => (_roleActif['sigle'] as String?) ?? '';

  @override
  Future<ResultatDecision> approuver(int rcId, {String? commentaire}) => _repondre(() {
    final d = _doc(rcId);
    _exigerDecision(d, 'approuver');
    if (_etape == 'SG' && d.estBc) {
      throw const ApiException(400, 'Ce RC est un Bon de Commande.', 'APPROVAL_REFUSED');
    }
    _exigerApprobation(d);
    final (action, statut) = _approbations[_etape]!;
    final e = _ajouter(
      d,
      action,
      statut,
      commentaire: commentaire?.trim().isEmpty ?? true ? null : commentaire!.trim(),
    );
    d.signatures.add({'par': moiDemo.nomComplet, 'type': _sigle, 'le': _iso(e.le)});
    return ResultatDecision.fromJson(_resultat(messagesStatut[statut] ?? 'Approuvé', statut, e.id));
  });

  static String _cleRole(String role) => switch (infoRoleKey(role)) {
    'DIRECTEUR_PROJET' => 'directeur_projet',
    'DIRECTEUR_EXPLOITATION' => 'directeur_exploitation',
    'RESPONSABLE_ETUDE' => 'responsable_etude',
    _ => 'responsable_projet',
  };

  @override
  Future<ResultatDecision> rejeter(int rcId, {required String motif, int? destinataireId}) => _repondre(() {
    final d = _doc(rcId);
    if (motif.trim().length < 3) throw const ApiException(400, 'Indiquez le motif du rejet', 'VALIDATION');
    _exigerDecision(d, 'rejeter');
    final etape = _etape;
    String statut;
    PersonneDemo? cible;
    if (etape == 'DP' || etape == 'DE') {
      statut = etape == 'DP' ? 'rejected_by_directeur_projet' : 'rejected_by_directeur_exploitation';
      final precedent = d.evenements.lastWhereOrNull(
        (e) => e.action == (etape == 'DP' ? 'APPROVED_BY_RESPONSABLE_PROJET' : 'APPROVED_BY_DIRECTEUR_PROJET'),
      );
      cible = precedent?.acteur;
    } else {
      if (destinataireId == null) {
        throw const ApiException(400, 'Choisissez à qui renvoyer le document', 'TARGET_REQUIRED');
      }
      final possibles = (asJson(detailJson(rcId)['actions'])['destinatairesRenvoi'] as List).cast<Json>();
      if (!possibles.any((p) => p['id'] == destinataireId)) {
        throw const ApiException(400, 'Ce destinataire ne participe pas au circuit de ce document', 'TARGET_INVALID');
      }
      cible = equipeDemo.firstWhere((p) => p.id == destinataireId);
      final origine = etape == 'SG' ? 'service_gestion' : 'responsable_etude';
      statut = 'rejected_by_${origine}_to_${_cleRole(cible.role)}';
    }
    final e = _ajouter(d, statut.toUpperCase(), statut, commentaire: motif.trim(), cible: cible);
    d.version += 1;
    return ResultatDecision.fromJson(
      _resultat(messagesStatut[statut] ?? 'Document renvoyé pour correction', statut, e.id),
    );
  });

  @override
  Future<ResultatDecision> demanderInfo(int rcId, {required int destinataireId, required String message}) =>
      _repondre(() {
        final d = _doc(rcId);
        if (_capacites(d)['peutDemanderInfo'] != true) {
          throw const ApiException(403, "Votre rôle ne peut pas faire de demande d'information", 'ROLE_NOT_DECIDER');
        }
        final cible = equipeDemo.where((p) => p.id == destinataireId && p.id != moiDemo.id).firstOrNull;
        if (cible == null) throw const ApiException(400, 'Destinataire invalide pour ce document', 'TARGET_INVALID');
        final e = _ajouter(
          d,
          'INFO_REQUEST_BY_${infoRoleKey(_nomRole)}_TO_${infoRoleKey(cible.role)}',
          d.statut,
          commentaire: message.trim(),
          cible: cible,
        );
        return ResultatDecision.fromJson(_resultat("Demande d'information envoyée", d.statut, e.id));
      });

  @override
  Future<ResultatDecision> repondreInfo(int rcId, {required String message}) => _repondre(() {
    final d = _doc(rcId);
    final demande = _demandePourMoi(d);
    if (demande == null) {
      throw const ApiException(
        403,
        "Aucune demande d'information ne vous est adressée sur ce document",
        'NO_INFO_REQUEST',
      );
    }
    final e = _ajouter(
      d,
      'INFO_RESPONSE_BY_${infoRoleKey(_nomRole)}_TO_${infoRoleKey(demande.acteur.role)}',
      d.statut,
      commentaire: message.trim(),
      cible: demande.acteur,
    );
    return ResultatDecision.fromJson(_resultat('Réponse envoyée', d.statut, e.id));
  });

  @override
  Future<ResultatDecision> bonDeCommande(int rcId, {required bool actif}) => _repondre(() {
    final d = _doc(rcId);
    if (_etape != 'SG') {
      throw const ApiException(403, 'Seul Service Gestion peut convertir un RC en Bon de Commande', 'ROLE_NOT_DECIDER');
    }
    if (actif) {
      _exigerDecision(d, 'approuver');
      _exigerApprobation(d);
      d.estBc = true;
      final e = _ajouter(d, 'APPROVED_BY_SERVICE_GESTION', 'approved_by_service_gestion');
      d.signatures.add({'par': moiDemo.nomComplet, 'type': 'SG', 'le': _iso(e.le)});
      return ResultatDecision.fromJson(
        _resultat('Converti en Bon de Commande et approuvé par Service Gestion', e.statut, e.id, estBc: true),
      );
    }
    d.estBc = false;
    return ResultatDecision.fromJson(_resultat('Conversion en Bon de Commande annulée', d.statut, null, estBc: false));
  });

  @override
  Future<ResultatPieces> envoyerPieces(
    int rcId,
    int evenementId,
    List<PieceLocale> pieces, {
    Progression? progression,
  }) => _repondre(() {
    final d = _doc(rcId);
    final e = d.evenements.where((x) => x.id == evenementId).firstOrNull;
    if (e == null) throw const ApiException(404, 'Événement introuvable sur ce document', 'EVENT_NOT_FOUND');
    if (e.acteur.id != moiDemo.id) {
      throw const ApiException(403, 'Vous ne pouvez joindre des pièces qu’à vos propres décisions', 'NOT_EVENT_AUTHOR');
    }
    if (_maintenant.difference(e.le) > const Duration(hours: 1)) {
      throw const ApiException(
        400,
        'Les pièces se joignent au moment de la décision (délai dépassé)',
        'UPLOAD_WINDOW_CLOSED',
      );
    }
    if (pieces.any((p) => (p.taille ?? 0) > 25 * 1024 * 1024)) {
      throw const ApiException(400, 'Fichier trop volumineux (25 Mo maximum par fichier)', 'FILE_TOO_LARGE');
    }
    final categorie = e.action.startsWith('APPROVED_BY_')
        ? 'approval'
        : e.action.startsWith('INFO_REQUEST_BY_')
        ? 'info_request'
        : e.action.startsWith('INFO_RESPONSE_BY_')
        ? 'info_response'
        : 'rejection';
    final total = pieces.fold<int>(0, (s, p) => s + (p.taille ?? 0));
    progression?.call(total, total);
    final ajoutees = [
      for (final p in pieces)
        {
          'id': ++_prochainId,
          'nom': p.nom,
          'taille': p.taille ?? 0,
          'type': p.type,
          'deposeLe': _iso(_maintenant),
          'categorie': categorie,
        },
    ];
    e.pieces.addAll(ajoutees);
    return ResultatPieces.fromJson({
      'succes': true,
      'message': '${ajoutees.length} fichier(s) joint(s)',
      'pieces': ajoutees,
    });
  });

  @override
  Future<List<FichierDossier>> fichiers(int rcId) =>
      _repondre(() => asList(_doc(rcId).fichiers, FichierDossier.fromJson));

  @override
  Future<File> telecharger(String chemin, String nom, {Progression? progression}) async {
    await _repondre(() {});
    final dossier = await getTemporaryDirectory();
    final excel = nom.toLowerCase().endsWith('.xlsx');
    final base = nom.contains('.') ? nom.substring(0, nom.lastIndexOf('.')) : nom;
    final local = await fichierTelechargement(dossier, excel ? '$base.csv' : '$base.pdf');
    final octets = excel
        ? [0xEF, 0xBB, 0xBF, ...utf8.encode('Document;$nom\nSource;Démonstration DG Flow RC (données fictives)\n')]
        : pdfDemonstration(nom, ['Fichier de démonstration : $nom', 'Les données de cette application sont fictives.']);
    progression?.call(octets.length, octets.length);
    await local.writeAsBytes(octets);
    return local;
  }

  // ─── Notifications ──────────────────────────────────────────────────────

  @override
  Future<PageNotifications> notifications({int? avant, int limite = 30, bool nonLuesSeulement = false}) => _repondre(
    () {
      final toutes = monde.notifications
          .where((n) => avant == null || (n['id'] as int) < avant)
          .where((n) => !nonLuesSeulement || n['lue'] != true)
          .toList();
      final page = toutes.take(limite).toList();
      return PageNotifications.fromJson({'elements': page, 'suivant': toutes.length > limite ? page.last['id'] : null});
    },
  );

  @override
  Future<int> nonLues() => _repondre(() => monde.notifications.where((n) => n['lue'] != true).length);

  @override
  Future<void> marquerLue(int id) => _repondre(() {
    final n = monde.notifications.where((x) => x['id'] == id).firstOrNull;
    if (n == null) throw const ApiException(404, 'Notification introuvable', 'NOT_FOUND');
    n['lue'] = true;
  });

  @override
  Future<int> toutLire() => _repondre(() {
    var n = 0;
    for (final x in monde.notifications) {
      if (x['lue'] != true) {
        x['lue'] = true;
        n++;
      }
    }
    return n;
  });
}

extension _Recherche<T> on List<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    for (var i = length - 1; i >= 0; i--) {
      if (test(this[i])) return this[i];
    }
    return null;
  }

  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

/// PDF d'une page (Helvetica, WinAnsi) : de quoi ouvrir une pièce en démonstration.
List<int> pdfDemonstration(String titre, List<String> lignes) {
  String echapper(String s) => s.replaceAll(r'\', r'\\').replaceAll('(', r'\(').replaceAll(')', r'\)');
  final contenu = StringBuffer('BT /F1 20 Tf 56 770 Td (${echapper(titre)}) Tj ET\n');
  var y = 730;
  for (final l in lignes) {
    contenu.write('BT /F1 12 Tf 56 $y Td (${echapper(l)}) Tj ET\n');
    y -= 20;
  }
  final flux = latin1.encode(contenu.toString().replaceAll(RegExp(r'[^\x00-\xFF]'), '-'));
  final objets = <List<int>>[
    latin1.encode('<< /Type /Catalog /Pages 2 0 R >>'),
    latin1.encode('<< /Type /Pages /Kids [3 0 R] /Count 1 >>'),
    latin1.encode(
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>',
    ),
    [...latin1.encode('<< /Length ${flux.length} >>\nstream\n'), ...flux, ...latin1.encode('\nendstream')],
    latin1.encode('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>'),
  ];
  final sortie = <int>[...latin1.encode('%PDF-1.4\n')];
  final positions = <int>[];
  for (var i = 0; i < objets.length; i++) {
    positions.add(sortie.length);
    sortie
      ..addAll(latin1.encode('${i + 1} 0 obj\n'))
      ..addAll(objets[i])
      ..addAll(latin1.encode('\nendobj\n'));
  }
  final xref = sortie.length;
  final table = StringBuffer('xref\n0 ${objets.length + 1}\n0000000000 65535 f \n');
  for (final p in positions) {
    table.write('${p.toString().padLeft(10, '0')} 00000 n \n');
  }
  table.write('trailer\n<< /Size ${objets.length + 1} /Root 1 0 R >>\nstartxref\n$xref\n%%EOF\n');
  sortie.addAll(latin1.encode(table.toString()));
  return sortie;
}
