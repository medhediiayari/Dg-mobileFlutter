import 'dart:convert';
import 'dart:io';

import 'package:dgflow_rc/core/models/models.dart';
import 'package:dgflow_rc/core/push/service_push.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixtures calquées sur les réponses du backend RN (modules/rc/lecture.ts,
/// parcours.ts, pieces.ts, notifications.routes.ts, me.routes.ts, auth.routes.ts).
dynamic fixture(String nom) => jsonDecode(File('test/fixtures/$nom.json').readAsStringSync());

void main() {
  group('Session', () {
    test('meta avec SSO Microsoft', () {
      final m = Meta.fromJson(fixture('meta'));
      expect(m.api, '1.4.0');
      expect(m.versionMinimaleApp, '1.0.0');
      expect(m.microsoft?.tenantId, '8a3f2c1e-1111-4a2b-9c3d-123456789abc');
      expect(m.microsoft?.clientId, startsWith('0d9e8f7a'));
    });

    test('meta sans SSO', () {
      final m = Meta.fromJson({
        'api': '1',
        'versionMinimaleApp': '2.0.0',
        'sso': {'microsoft': null},
      });
      expect(m.microsoft, isNull);
    });

    test('réponse de connexion et profil multi-rôles', () {
      final r = ReponseConnexion.fromJson(fixture('connexion'));
      expect(r.expiresIn, 900);
      expect(r.refreshToken.length, greaterThan(40));
      final u = r.utilisateur;
      expect(u.nomComplet, 'Camille Lefèvre');
      expect(u.initiales, 'CL');
      expect(u.roleActif.sigle, 'DP');
      expect(u.roles, hasLength(3));
      expect(u.plusieursRoles, isTrue);
      expect(u.roles.last.etape, isNull);
      expect(u.roles.last.monogramme, 'D');
      expect(u.lectureSeule, isFalse);
    });

    test('rafraîchissement', () {
      final j = JetonsRafraichis.fromJson(fixture('refresh'));
      expect(j.accessToken, 'nouveau-acces');
      expect(j.expiresIn, 900);
    });

    test('sessions (appareils connectés)', () {
      final s = asList(fixture('sessions'), SessionAppareil.fromJson);
      expect(s, hasLength(2));
      expect(s.first.courante, isTrue);
      expect(s.first.appareil, 'Google Pixel 8');
      expect(s.last.appareil, isNull);
      expect(s.first.utiliseLe.toUtc(), DateTime.utc(2026, 10, 19, 9));
    });
  });

  group('Liste', () {
    test('éléments, compteurs, libellés', () {
      final l = ReponseListe.fromJson(fixture('liste'));
      expect(l.total, 27);
      expect(l.aSuivre, isTrue);
      expect(l.enAttenteReception, 2);
      expect(l.compteurs[Bucket.pending], 2);
      expect(l.compteurs[Bucket.approved], 12);
      expect(l.compteurs.aTraiter, 4);
      expect(l.compteurs.infoPourMoi, 1);
      expect(l.libellesBuckets[Bucket.rejected], 'Rejetés / renvoyés');

      final rc = l.elements.first;
      expect(rc.type, TypeDocument.rc);
      expect(rc.ton, Ton.info);
      expect(rc.bucket, Bucket.pending);
      expect(rc.entreprise?.montant, 1326480.5);
      expect(rc.dernierEvenement?.par, 'Julien Marchand');
      expect(rc.consultationRequise, contains('Consultez'));

      final av = l.elements.last;
      expect(av.type, TypeDocument.avenant);
      expect(av.numeroAvenant, 1);
      expect(av.projet.code, isNull);
      expect(av.bucket, isNull);
      expect(av.ton, Ton.alerte);
      expect(av.entreprise, isNull);
      expect(av.infoPourMoi, isTrue);
      expect(av.estBc, isTrue);
    });

    test('paramètres de requête', () {
      const f = FiltresListe(vue: 'tous', bucket: Bucket.rejected, type: TypeDocument.avenant, q: '  lot 02 ');
      expect(f.parametres(page: 2, limite: 25), {
        'vue': 'tous',
        'page': '2',
        'limite': '25',
        'bucket': 'rejected',
        'type': 'AVENANT',
        'q': 'lot 02',
      });
      expect(FiltresListe.aTraiter.parametres(page: 1, limite: 25), {'vue': 'a-traiter', 'page': '1', 'limite': '25'});
      expect(const FiltresListe(vue: 'tous', q: 'a'), const FiltresListe(vue: 'tous', q: 'a'));
    });
  });

  group('Fiche', () {
    test('RC renvoyé, paiement incohérent, demande d’information répondue', () {
      final d = Detail.fromJson(fixture('detail_rc'));
      expect(d.reference, 'GRE-23-112-RC-009');
      expect(d.version, 2);
      expect(d.ton, Ton.danger);
      expect(d.estAvenant, isFalse);
      expect(d.libelleType, 'RC');
      // Decimal Prisma sérialisé en chaîne : lu quand même.
      expect(d.montants.budgetPrestation, 312000.5);
      expect(d.montants.ecartsSstEtude, -1520.4);
      expect(d.montants.avenant, isNull);
      expect(d.paiement.erreur, isNotNull);
      expect(d.conditions.nbreHeuresInsertion, 350);
      expect(d.conditions.pourcentageProrata, '1,5');
      expect(d.entreprise.aUnContact, isTrue);
      expect(d.entreprisesConsultees.last.montant, isNull);
      expect(d.identification.dateFin, '2027-04-15T00:00:00.000Z');
      expect(d.rejet?.auteur, 'DEX');
      expect(d.rejet?.pieces.single.categorie, 'rejection');
      expect(d.rejet?.pieces.single.taille, 2316800);
      expect(d.messageEntrant?.message, 'Envoi pour validation.');
      expect(d.demandeInfo?.reponse?.message, 'Oui, 14 semaines.');
      expect(d.demandeInfo?.pourMoi, isFalse);
      expect(d.tableau?.genre, GenreTableau.comparatif);
      expect(d.nomTableau, 'Tableau comparatif');
      expect(d.nombreFichiers, 2);
      expect(d.consultation.perimee, isTrue);
      expect(d.consultation.autorise, isFalse);
      expect(d.consultation.consulteLe?.toUtc(), DateTime.utc(2026, 10, 15, 7));
      expect(d.actions.peutApprouver, isTrue);
      expect(d.actions.decideur, isTrue);
      expect(d.actions.paiementBloquant, isNotNull);
      expect(d.actions.etape?.sigle, 'DP');
      expect(d.actions.destinatairesInfo.map((x) => x.id), [26, 23]);
      expect(d.actions.destinatairePropose, 26);
      expect(d.avenants.single.ton, Ton.neutre);
    });

    test('avenant tiré du tableau explicatif', () {
      final d = Detail.fromJson(fixture('detail_avenant'));
      expect(d.estAvenant, isTrue);
      expect(d.libelleType, 'Avenant 1');
      expect(d.rcParent?.id, 140);
      expect(d.montants.montantDepuisTableauExplicatif, isTrue);
      expect(d.montants.avenant?.marge, 5390);
      expect(d.montants.avenant?.ecart, 2330);
      expect(d.tableau?.genre, GenreTableau.explicatif);
      expect(d.nomTableau, 'Tableau explicatif');
      expect(d.actions.peutConvertirBc, isTrue);
      expect(d.actions.signatureManquante, isTrue);
      expect(d.actions.rejetAvecDestinataire, isTrue);
      expect(d.actions.destinatairesRenvoi.single.nom, 'Nadia Haddad');
      expect(d.entreprise.aUnContact, isFalse);
    });

    test('mise à jour de la garde sans relire la fiche', () {
      final d = Detail.fromJson(fixture('detail_rc'));
      final c = Consultation.fromJson({
        'autorise': true,
        'documentOk': true,
        'tableauOk': true,
        'tableauRequis': true,
        'perimee': false,
        'message': null,
        'consulteLe': '2026-10-19T09:00:00.000Z',
        'consulteTableauLe': '2026-10-15T07:00:00.000Z',
      });
      final maj = d.avecConsultation(c);
      expect(maj.consultation.autorise, isTrue);
      expect(maj.reference, d.reference);
      expect(maj.actions, same(d.actions));
    });
  });

  group('Parcours, tableaux, décisions, fichiers, notifications', () {
    test('parcours', () {
      final p = Parcours.fromJson(fixture('parcours'));
      expect(p.etapes, hasLength(5));
      expect(p.etapes.first.id, isNull);
      expect(p.etapes[1].automatique, isTrue);
      expect(p.etapes[2].etat, EtatEtape.info);
      expect(p.etapes[2].pieces.single.nom, 'Avis BC variante ITE.pdf');
      expect(p.etapes[3].etat, EtatEtape.rejected);
      expect(p.etapes[3].motif, 'Pièces manquantes');
      expect(p.etapes.last.etat, EtatEtape.current);
      expect(p.etapes.last.le, isNull);
    });

    test('tableau comparatif', () {
      final t = Tableau.fromJson(fixture('tableau_comparatif'));
      expect(t, isA<TableauComparatif>());
      final c = t as TableauComparatif;
      expect(c.totaux.etudeRecale, 1370000);
      expect(c.entreprises.first.retenue, isTrue);
      expect(c.entreprises.last.prixManquants, 1);
      expect(c.articles.first.titre, isTrue);
      expect(c.articles.last.transfere, isTrue);
      expect(c.articles.last.prix.first.total, 49020);
      expect(c.articles.last.prix.last.total, isNull);
    });

    test('tableau explicatif', () {
      final t = Tableau.fromJson(fixture('tableau_explicatif')) as TableauExplicatif;
      expect(t.fgTaux, 0.05);
      expect(t.cloture, isTrue);
      expect(t.lignes.last.isSousLigne, isTrue);
      expect(t.lignes.last.montantClient, isNull);
      expect(t.totaux.montantAvenant, 48650);
    });

    test('pas de tableau', () {
      expect(Tableau.fromJson({'genre': null}), isA<TableauAbsent>());
    });

    test('résultat de décision et pièces jointes', () {
      final r = ResultatDecision.fromJson(fixture('decision'));
      expect(r.succes, isTrue);
      expect(r.evenementId, 9001);
      expect(r.statut, 'approved_by_directeur_projet');
      expect(r.estBc, isNull);
      final bc = ResultatDecision.fromJson({
        'succes': true,
        'message': 'x',
        'statut': 's',
        'evenementId': null,
        'estBc': false,
      });
      expect(bc.evenementId, isNull);
      expect(bc.estBc, isFalse);
      final p = ResultatPieces.fromJson(fixture('pieces'));
      expect(p.pieces, hasLength(2));
      expect(p.pieces.first.categorie, 'approval');
    });

    test('dossier « Fichiers »', () {
      final f = asList(asJson(fixture('fichiers'))['elements'], FichierDossier.fromJson);
      expect(f.first.categorie?.couleur, '#1D539D');
      expect(f.first.dossier, isNull);
      expect(f.last.dossier, 'Plans');
      expect(f.last.deposePar, isNull);
    });

    test('notifications', () {
      final n = PageNotifications.fromJson(fixture('notifications'));
      expect(n.suivant, 5010);
      expect(n.elements.first.lue, isFalse);
      expect(n.elements.first.rcId, 142);
      expect(n.elements.last.rcId, isNull);
      expect(n.elements.first.marqueeLue().lue, isTrue);
    });

    test('lecture tolérante', () {
      expect(asDoubleOrNull('12,5'), 12.5);
      expect(asDoubleOrNull('abc'), isNull);
      expect(asIntOrNull('42'), 42);
      expect(asIntOrNull(3.9), 3);
      expect(asBool('true'), isTrue);
      expect(asBool(1), isTrue);
      expect(asDateOrNull(''), isNull);
      expect(Ton.depuis('inconnu'), Ton.neutre);
      expect(Bucket.depuis('approved'), Bucket.approved);
      expect(Bucket.depuis(null), isNull);
    });
  });

  test('notification push : valeurs `data` en chaînes (FCM)', () {
    final o = OuverturePush.depuis({
      'notificationId': '5016',
      'rcId': '142',
      'projetId': '101',
      'type': 'RC_APPROVAL_REQUIRED',
    });
    expect(o.rcId, 142);
    expect(o.notificationId, 5016);
    final sansRc = OuverturePush.depuis({'notificationId': '5010', 'type': 'RC_PROJECT_ASSIGNED'});
    expect(sansRc.rcId, isNull);
    expect(sansRc.notificationId, 5010);
  });

  test('montants entiers écrits sans décimale (comme JavaScript)', () {
    final e = EntrepriseConsultee.fromJson({
      'id': 1,
      'nom': 'X',
      'montant': 12500,
      'observations': null,
      'retenue': true,
    });
    expect(e.montant, 12500.0);
    final t = TotauxComparatif.fromJson({'budgetEtude': 1, 'transfert': 0, 'etudeRecale': 2, 'objectif': 3});
    expect(t.etudeRecale, 2.0);
  });
}
