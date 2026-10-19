import 'package:dgflow_rc/app/app.dart';
import 'package:dgflow_rc/core/auth/coffre.dart';
import 'package:dgflow_rc/core/api/api_exception.dart';
import 'package:dgflow_rc/core/demo/api_demo.dart';
import 'package:dgflow_rc/core/models/models.dart';
import 'package:dgflow_rc/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Tests d'écrans en mode démonstration : mêmes fixtures que l'application.
Future<void> avancer(WidgetTester tester, [int images = 16]) async {
  for (var i = 0; i < images; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<ApiDemo> lancer(WidgetTester tester, {bool connecter = true, ApiDemo? demo}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  final api = demo ?? ApiDemo(latence: Duration.zero);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        apiProvider.overrideWithValue(api),
        coffreProvider.overrideWithValue(CoffreMemoire()),
        infosAppProvider.overrideWithValue(const InfosApp(version: '1.0.0', nomAppareil: 'Test')),
      ],
      child: const DgFlowApp(),
    ),
  );
  await avancer(tester);
  if (connecter) {
    await tester.enterText(find.byType(TextField).at(0), 'camille.lefevre@dggroup.fr');
    await tester.enterText(find.byType(TextField).at(1), 'secret');
    await tester.tap(find.text('Se connecter'));
    await avancer(tester, 24);
  }
  return api;
}

Future<void> toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await avancer(tester);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
    Intl.defaultLocale = 'fr_FR';
  });

  testWidgets('connexion : erreur sans mot de passe, puis file « À traiter » et compteurs', (tester) async {
    await lancer(tester, connecter: false);
    expect(find.text('Parcours RC'), findsOneWidget);
    expect(find.text('Se connecter avec DG Group'), findsNothing, reason: 'SSO non configuré dans /meta');

    await tester.tap(find.text('Se connecter'));
    await avancer(tester);
    expect(find.text('Saisissez votre email et votre mot de passe.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'camille.lefevre@dggroup.fr');
    await tester.enterText(find.byType(TextField).at(1), 'secret');
    await tester.tap(find.text('Se connecter'));
    await avancer(tester, 24);

    expect(find.text('4 documents attendent votre décision'), findsOneWidget);
    expect(find.text('dont 1 demande d’information'), findsOneWidget);
    expect(find.text('En attente'), findsOneWidget);
    expect(find.text('Renvoyés'), findsOneWidget);
    expect(find.text('Gros œuvre — bâtiment A'), findsOneWidget);
    expect(find.text('1 projet sans accusé de réception'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Une information vous est demandée'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Une information vous est demandée'), findsOneWidget);
  });

  testWidgets('fiche : lecture enregistrée à l’affichage, tableau consulté, approbation signée', (tester) async {
    await lancer(tester);
    await toucher(tester, find.text('Gros œuvre — bâtiment A'));
    await avancer(tester, 20);

    expect(find.text('À vous de décider'), findsOneWidget);
    expect(find.text('Message de Julien Marchand'), findsOneWidget);
    // La fiche s'est affichée : sa lecture est enregistrée, reste le tableau.
    expect(find.text('Fiche lue'), findsOneWidget);
    expect(find.text("Consultez le tableau comparatif avant d'approuver."), findsOneWidget);

    await tester.tap(find.text('Ouvrir').last);
    await avancer(tester, 20);
    expect(find.text('Tableau comparatif'), findsWidgets);
    expect(find.text('Lecture du tableau enregistrée'), findsOneWidget);
    expect(find.text('Bâti Rhône Construction'), findsWidgets);

    await tester.tap(find.byType(BackButton));
    await avancer(tester, 20);
    expect(find.text("Consultez le tableau comparatif avant d'approuver."), findsNothing);

    await tester.tap(find.text('Approuver'));
    await avancer(tester, 20);
    expect(find.text('Votre signature sera apposée'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Bon pour accord.');
    await toucher(tester, find.text('Approuver et signer').last);
    await avancer(tester, 20);
    expect(find.text('C’est fait'), findsOneWidget);
    expect(find.text("Approuvé — transmis au Directeur d'Exploitation"), findsOneWidget);

    await tester.tap(find.text('Retour à la fiche'));
    await avancer(tester, 24);
    expect(find.text("Chez le directeur d'exploitation"), findsOneWidget);
  });

  testWidgets('renvoi : motif obligatoire, paiement incohérent bloque l’approbation', (tester) async {
    await lancer(tester);
    await tester.scrollUntilVisible(
      find.text('Menuiseries extérieures aluminium'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await toucher(tester, find.text('Menuiseries extérieures aluminium'));
    await avancer(tester, 20);

    expect(find.text('Motif du renvoi (DEX)'), findsOneWidget);
    expect(find.text('Paiement incohérent : approbation impossible, renvoyez le document.'), findsOneWidget);
    final approuver = tester.widget<ButtonStyleButton>(
      find.ancestor(of: find.text('Approuver'), matching: find.bySubtype<ButtonStyleButton>()),
    );
    expect(approuver.onPressed, isNull);

    await tester.tap(find.text('Rejeter'));
    await avancer(tester, 20);
    await toucher(tester, find.text('Rejeter').last);
    expect(find.text('Indiquez le motif du rejet (3 caractères minimum).'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Faire corriger la répartition Direct / COREDIF.');
    await toucher(tester, find.text('Rejeter').last);
    await avancer(tester, 20);
    expect(find.text('C’est fait'), findsOneWidget);
    expect(find.text('Rejeté — renvoyé au Responsable de Projet'), findsOneWidget);
  });

  testWidgets('alertes : non-lues, tout marquer comme lu', (tester) async {
    await lancer(tester);
    await tester.tap(find.text('Alertes').last);
    await avancer(tester, 20);
    expect(find.text('RC à valider'), findsOneWidget);
    expect(find.text("Aujourd'hui"), findsOneWidget);
    expect(find.text('Tout marquer comme lu'), findsOneWidget);
    await tester.tap(find.text('Tout marquer comme lu'));
    await avancer(tester, 20);
    expect(find.text('Tout marquer comme lu'), findsNothing);
  });

  testWidgets('profil : push non configuré, appareils, changement de rôle', (tester) async {
    await lancer(tester);
    await tester.tap(find.text('Profil').last);
    await avancer(tester, 20);
    expect(find.text('Camille Lefèvre'), findsOneWidget);
    expect(find.text('Notifications non configurées'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Google Pixel 8'), 200, scrollable: find.byType(Scrollable).last);
    expect(find.text('Ce téléphone'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Changer'), -200, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Changer'));
    await avancer(tester, 20);
    expect(find.text('Agir en tant que'), findsOneWidget);
    await tester.tap(find.text('Service Gestion'));
    await avancer(tester, 24);
    expect(find.text('Agir en tant que'), findsNothing);
    expect(find.text('Service Gestion'), findsOneWidget);

    await tester.tap(find.text('À traiter').last);
    await avancer(tester, 24);
    // 148 à convertir en BC + la demande d'information adressée à l'utilisateur (quel que soit le rôle).
    expect(find.text('2 documents attendent votre décision'), findsOneWidget);
    expect(find.text('Peinture, sols souples'), findsOneWidget);
  });

  testWidgets('suivi : filtres et recherche', (tester) async {
    await lancer(tester);
    await tester.tap(find.text('Suivi').last);
    await avancer(tester, 20);
    expect(find.text('10 documents'), findsOneWidget);
    await tester.tap(find.text('Avenants'));
    await avancer(tester, 20);
    expect(find.text('1 document'), findsOneWidget);
    await tester.tap(find.text('RC et avenants'));
    await avancer(tester, 10);
    await tester.enterText(find.byType(TextField).first, 'clinique');
    await avancer(tester, 20);
    expect(find.text('3 documents'), findsOneWidget);
  });

  testWidgets('démarrage : version minimale non atteinte', (tester) async {
    await lancer(tester, connecter: false, demo: _ApiVersionMinimale());
    expect(find.text('Mise à jour requise'), findsOneWidget);
    expect(find.textContaining('minimum 9.0.0'), findsOneWidget);
  });

  testWidgets('démarrage : serveur injoignable, puis « Réessayer »', (tester) async {
    final api = _ApiHorsLigne();
    await lancer(tester, connecter: false, demo: api);
    expect(find.textContaining('Serveur injoignable'), findsOneWidget);
    api.enLigne = true;
    await tester.tap(find.text('Réessayer'));
    await avancer(tester, 16);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}

class _ApiVersionMinimale extends ApiDemo {
  _ApiVersionMinimale() : super(latence: Duration.zero);

  @override
  Future<Meta> meta() async => Meta.fromJson({
    'api': '2.0.0',
    'versionMinimaleApp': '9.0.0',
    'sso': {'microsoft': null},
  });
}

class _ApiHorsLigne extends ApiDemo {
  _ApiHorsLigne() : super(latence: Duration.zero);

  bool enLigne = false;

  @override
  Future<Meta> meta() async {
    if (!enLigne) {
      throw const ApiException(0, 'Serveur injoignable. Vérifiez votre connexion.', ApiException.codeReseau);
    }
    return super.meta();
  }
}
