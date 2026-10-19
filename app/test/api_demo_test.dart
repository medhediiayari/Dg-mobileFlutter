import 'package:dgflow_rc/core/api/api_exception.dart';
import 'package:dgflow_rc/core/api/dgflow_api.dart';
import 'package:dgflow_rc/core/demo/api_demo.dart';
import 'package:dgflow_rc/core/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher codeApi(String code) => throwsA(isA<ApiException>().having((e) => e.code, 'code', code));

Future<ApiDemo> connecte({bool signature = true}) async {
  final api = ApiDemo(maintenant: DateTime(2026, 10, 19, 10), latence: Duration.zero, aUneSignature: signature);
  await api.connexion(email: 'camille.lefevre@dggroup.fr', motDePasse: 'x');
  return api;
}

void main() {
  test('connexion refusée sans identifiants valides, puis profil multi-rôles', () async {
    final api = ApiDemo(latence: Duration.zero);
    await expectLater(api.moi(), codeApi('TOKEN_INVALID'));
    await expectLater(api.connexion(email: 'x', motDePasse: 'y'), codeApi('INVALID_CREDENTIALS'));
    final r = await api.connexion(email: 'camille.lefevre@dggroup.fr', motDePasse: 'x');
    expect(r.utilisateur.roles, hasLength(4));
    expect(r.utilisateur.roleActif.sigle, 'DP');
  });

  test('file « À traiter » du DP : décisions, renvoi et demande d’information', () async {
    final api = await connecte();
    final l = await api.liste(FiltresListe.aTraiter);
    expect(l.elements.map((e) => e.id).toSet(), {142, 143, 144, 146});
    expect(l.total, 4);
    expect(l.compteurs.infoPourMoi, 1);
    expect(l.compteurs[Bucket.pending], 2);
    expect(l.compteurs[Bucket.rejected], 1);
    expect(l.elements.firstWhere((e) => e.id == 146).infoPourMoi, isTrue);
    expect(l.elements.firstWhere((e) => e.id == 142).consultationRequise, "Consultez le RC avant d'approuver.");
    expect(l.enAttenteReception, 1);
  });

  test('suivi : filtres par état, type et recherche', () async {
    final api = await connecte();
    final avenants = await api.liste(const FiltresListe(vue: 'tous', type: TypeDocument.avenant));
    expect(avenants.elements.single.id, 144);
    final valides = await api.liste(const FiltresListe(vue: 'tous', bucket: Bucket.approved));
    expect(valides.elements.every((e) => e.bucket == Bucket.approved), isTrue);
    final recherche = await api.liste(const FiltresListe(vue: 'tous', q: 'tilleuls façades'));
    expect(recherche.elements.single.id, 146);
    final page = await api.liste(const FiltresListe(vue: 'tous'), limite: 4);
    expect(page.aSuivre, isTrue);
    expect(page.elements, hasLength(4));
  });

  test('garde de consultation : fiche, puis tableau, puis approbation et pièces', () async {
    final api = await connecte();
    var d = await api.detail(142);
    expect(d.actions.peutApprouver, isTrue);
    expect(d.consultation.documentOk, isFalse);
    await expectLater(api.approuver(142), codeApi('CONSULTATION_REQUISE'));

    final c = await api.enregistrerConsultation(142, TypeConsultation.document);
    expect(c.documentOk, isTrue);
    expect(c.tableauOk, isFalse);
    await expectLater(api.approuver(142), codeApi('CONSULTATION_TABLEAU_REQUISE'));
    await expectLater(api.rejeter(142, motif: 'Incomplet'), codeApi('CONSULTATION_TABLEAU_REQUISE'));

    final t = await api.tableau(142);
    expect(t, isA<TableauComparatif>());
    await api.enregistrerConsultation(142, TypeConsultation.tableau);
    final r = await api.approuver(142, commentaire: 'Bon pour accord');
    expect(r.statut, 'approved_by_directeur_projet');
    expect(r.message, "Approuvé — transmis au Directeur d'Exploitation");
    expect(r.evenementId, isNotNull);

    final p = await api.envoyerPieces(142, r.evenementId!, const [
      PieceLocale(chemin: '/tmp/photo.jpg', nom: 'photo.jpg', type: 'image/jpeg', taille: 1000),
    ]);
    expect(p.pieces.single.categorie, 'approval');

    d = await api.detail(142);
    expect(d.actions.peutApprouver, isFalse);
    expect(d.statut, 'approved_by_directeur_projet');
    expect(d.signatures.last.par, 'Camille Lefèvre');
    final parcours = await api.parcours(142);
    expect(parcours.etapes.last.etat, EtatEtape.current);
    expect(parcours.etapes[parcours.etapes.length - 2].pieces.single.nom, 'photo.jpg');
    await expectLater(api.approuver(142), codeApi('WRONG_STATUS'));
  });

  test('fiche modifiée depuis la lecture, puis paiement incohérent', () async {
    final api = await connecte();
    final d = await api.detail(143);
    expect(d.consultation.perimee, isTrue);
    expect(d.rejet?.auteur, 'DEX');
    expect(d.actions.paiementBloquant, isNotNull);
    await expectLater(api.approuver(143), codeApi('CONSULTATION_PERIMEE'));
    await api.enregistrerConsultation(143, TypeConsultation.document);
    await expectLater(api.approuver(143), codeApi('PAIEMENT_INCOHERENT'));
    final r = await api.rejeter(143, motif: 'Corriger la répartition du paiement');
    expect(r.statut, 'rejected_by_directeur_projet');
  });

  test('signature manquante : approbation refusée, rejet possible', () async {
    final api = await connecte(signature: false);
    await api.enregistrerConsultation(144, TypeConsultation.document);
    await api.enregistrerConsultation(144, TypeConsultation.tableau);
    final d = await api.detail(144);
    expect(d.actions.signatureManquante, isTrue);
    await expectLater(api.approuver(144), codeApi('SIGNATURE_MANQUANTE'));
    expect((await api.rejeter(144, motif: 'À revoir')).statut, 'rejected_by_directeur_projet');
  });

  test('demande d’information : réponse du DP', () async {
    final api = await connecte();
    final d = await api.detail(146);
    expect(d.actions.peutRepondreInfo, isTrue);
    expect(d.demandeInfo?.pourMoi, isTrue);
    final r = await api.repondreInfo(146, message: 'Oui, validée par le bureau de contrôle.');
    expect(r.message, 'Réponse envoyée');
    final apres = await api.detail(146);
    expect(apres.demandeInfo?.reponse?.par, 'Camille Lefèvre');
    expect(apres.actions.peutRepondreInfo, isFalse);
    await expectLater(api.repondreInfo(146, message: 'encore'), codeApi('NO_INFO_REQUEST'));
  });

  test('Directeur d’Études : renvoi avec destinataire obligatoire', () async {
    final api = await connecte();
    await api.changerRole(5);
    final l = await api.liste(FiltresListe.aTraiter);
    expect(l.elements.map((e) => e.id), containsAll([150]));
    final d = await api.detail(150);
    expect(d.actions.rejetAvecDestinataire, isTrue);
    expect(d.actions.destinatairesRenvoi.any((x) => x.role.contains('Etude')), isFalse);
    await api.enregistrerConsultation(150, TypeConsultation.document);
    await expectLater(api.rejeter(150, motif: 'DC4 manquant'), codeApi('TARGET_REQUIRED'));
    await expectLater(api.rejeter(150, motif: 'DC4 manquant', destinataireId: 999), codeApi('TARGET_INVALID'));
    final r = await api.rejeter(150, motif: 'DC4 manquant', destinataireId: 23);
    expect(r.statut, 'rejected_by_responsable_etude_to_directeur_exploitation');
  });

  test('Service Gestion : conversion en Bon de Commande', () async {
    final api = await connecte();
    await api.changerRole(6);
    final d = await api.detail(148);
    expect(d.actions.peutConvertirBc, isTrue);
    await expectLater(api.bonDeCommande(148, actif: true), codeApi('CONSULTATION_REQUISE'));
    await api.enregistrerConsultation(148, TypeConsultation.document);
    await api.enregistrerConsultation(148, TypeConsultation.tableau);
    final r = await api.bonDeCommande(148, actif: true);
    expect(r.estBc, isTrue);
    expect(r.statut, 'approved_by_service_gestion');
    expect((await api.detail(148)).estBc, isTrue);
  });

  test('rôle en consultation : rien à décider', () async {
    final api = await connecte();
    final p = await api.changerRole(9);
    expect(p.lectureSeule, isTrue);
    final d = await api.detail(142);
    expect(d.actions.decideur, isFalse);
    expect(d.actions.motif, 'Consultation seule pour votre rôle.');
    await expectLater(api.approuver(142), codeApi('ROLE_NOT_DECIDER'));
  });

  test('notifications : pagination, lecture, tout lire', () async {
    final api = await connecte();
    expect(await api.nonLues(), 3);
    final p1 = await api.notifications(limite: 4);
    expect(p1.elements, hasLength(4));
    expect(p1.suivant, isNotNull);
    final p2 = await api.notifications(avant: p1.suivant, limite: 4);
    expect(p2.suivant, isNull);
    await api.marquerLue(p1.elements.first.id);
    expect(await api.nonLues(), 2);
    expect(await api.toutLire(), 2);
    expect(await api.nonLues(), 0);
  });

  test('fichiers et sessions', () async {
    final api = await connecte();
    final f = await api.fichiers(142);
    expect(f.where((x) => x.dossier == 'Plans'), hasLength(2));
    final s = await api.sessions();
    expect(s.where((x) => x.courante), hasLength(1));
    await api.revoquerSession(s.last.sid);
    expect(await api.sessions(), hasLength(s.length - 1));
  });

  test('document hors de portée du rôle', () async {
    final api = await connecte();
    await api.changerRole(6);
    await expectLater(api.detail(149), codeApi('RC_NOT_FOUND'));
  });
}
