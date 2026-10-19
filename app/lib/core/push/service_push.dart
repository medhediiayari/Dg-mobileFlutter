import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../api/dgflow_api.dart';
import '../auth/coffre.dart';
import '../config/app_config.dart';

enum ResultatPush { active, refusee, indisponible }

/// Notification touchée par l'utilisateur.
class OuverturePush {
  const OuverturePush({this.rcId, this.notificationId});

  final int? rcId;
  final int? notificationId;

  static OuverturePush depuis(Map<String, dynamic> data) {
    int? entier(Object? v) => v is int ? v : int.tryParse('${v ?? ''}');
    return OuverturePush(rcId: entier(data['rcId']), notificationId: entier(data['notificationId']));
  }
}

/// Notifications push via Firebase Cloud Messaging.
///
/// Firebase n'est pas encore configuré (pas de google-services.json /
/// GoogleService-Info.plist) : `Firebase.initializeApp()` échoue alors, et le
/// service se déclare indisponible sans gêner le reste de l'application.
/// Le jeton déclaré à l'API (`POST /me/appareils`) est le jeton FCM.
class ServicePush extends ChangeNotifier {
  ServicePush({required this.coffre, this.initialiserFirebase});

  final Coffre coffre;

  /// `Firebase.initializeApp()` protégé ; absent en test et sans Firebase.
  final Future<bool> Function()? initialiserFirebase;
  Future<void>? _demarrage;
  bool _disponible = false;

  /// Firebase initialisé (connu après [demarrer]).
  bool get disponible => _disponible;

  /// Initialise Firebase en arrière-plan : son échec (pas de configuration)
  /// prend plusieurs secondes et ne doit pas retarder l'ouverture de l'app.
  Future<void> demarrer() => _demarrage ??= _demarrer();

  Future<void> _demarrer() async {
    final init = initialiserFirebase;
    _disponible = init != null && await init();
    notifyListeners();
    if (_disponible) await initialiser();
  }

  final StreamController<OuverturePush> _ouvertures = StreamController.broadcast();
  final FlutterLocalNotificationsPlugin _locales = FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _renouvellement;
  OuverturePush? _enAttente;
  bool _initialise = false;

  static const String canal = 'rc';

  /// Notifications touchées pendant que l'application tourne.
  Stream<OuverturePush> get ouvertures => _ouvertures.stream;

  /// Notification qui a lancé l'application (consommée une seule fois).
  OuverturePush? prendreEnAttente() {
    final o = _enAttente;
    _enAttente = null;
    return o;
  }

  void _ouvrir(Map<String, dynamic> data) {
    final o = OuverturePush.depuis(data);
    if (_ouvertures.hasListener) {
      _ouvertures.add(o);
    } else {
      _enAttente = o;
    }
  }

  /// Écoute les messages (premier plan, ouverture depuis l'arrière-plan, lancement).
  Future<void> initialiser() async {
    if (!_disponible || _initialise) return;
    _initialise = true;
    try {
      await _locales.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (r) {
          final p = r.payload;
          if (p == null) return;
          try {
            _ouvrir((jsonDecode(p) as Map).cast<String, dynamic>());
          } catch (_) {}
        },
      );
      await _locales
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              canal,
              'Circuit de validation RC',
              description: 'Documents à décider, renvois et demandes d’information',
              importance: Importance.high,
            ),
          );

      // Premier plan : FCM n'affiche rien sur Android, on relaie par une notification locale.
      FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        if (n == null) return;
        _locales.show(
          id: m.hashCode & 0x7fffffff,
          title: n.title,
          body: n.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              canal,
              'Circuit de validation RC',
              importance: Importance.high,
              priority: Priority.high,
              color: Color(0xFF172D4C),
            ),
            iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: true),
          ),
          payload: jsonEncode(m.data),
        );
      });
      FirebaseMessaging.onMessageOpenedApp.listen((m) => _ouvrir(m.data));
      // Notification locale (reçue au premier plan) touchée alors que l'app était fermée.
      final lancement = await _locales.getNotificationAppLaunchDetails();
      final charge = lancement?.notificationResponse?.payload;
      if (lancement?.didNotificationLaunchApp == true && charge != null) {
        try {
          _ouvrir((jsonDecode(charge) as Map).cast<String, dynamic>());
        } catch (_) {}
      }
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _ouvrir(initial.data);
    } catch (e) {
      debugPrint('[push] initialisation impossible : $e');
    }
  }

  /// Identifiant stable de cette installation (`[A-Za-z0-9_-]{8,128}`).
  Future<String> idInstallation() async {
    final existant = await coffre.lire(Cles.installation);
    if (existant != null && RegExp(r'^[A-Za-z0-9_-]{8,128}$').hasMatch(existant)) return existant;
    final r = Random.secure();
    const alphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-';
    final nouveau = List.generate(32, (_) => alphabet[r.nextInt(alphabet.length)]).join();
    await coffre.ecrire(Cles.installation, nouveau);
    return nouveau;
  }

  /// Demande l'autorisation, obtient le jeton FCM et le déclare à l'API. Ne lève jamais.
  Future<ResultatPush> activer(DgFlowApi api) async {
    await demarrer();
    if (!_disponible) return ResultatPush.indisponible;
    try {
      await initialiser();
      final reglages = await FirebaseMessaging.instance.requestPermission();
      if (reglages.authorizationStatus == AuthorizationStatus.denied) return ResultatPush.refusee;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // Sans jeton APNs (simulateur, capacité Push absente), FCM ne peut pas fournir le sien.
        if (await FirebaseMessaging.instance.getAPNSToken() == null) return ResultatPush.indisponible;
      }
      // Le contrat de l'API attend le jeton d'enregistrement FCM (envoi par jeton),
      // pas l'identifiant d'installation (FID) des nouvelles API register().
      // ignore: deprecated_member_use
      final jeton = await FirebaseMessaging.instance.getToken();
      if (jeton == null || jeton.isEmpty) return ResultatPush.indisponible;
      final installation = await idInstallation();
      await api.enregistrerAppareil(installationId: installation, jeton: jeton, plateforme: AppConfig.plateforme);
      await _renouvellement?.cancel();
      // ignore: deprecated_member_use
      _renouvellement = FirebaseMessaging.instance.onTokenRefresh.listen((nouveau) {
        api
            .enregistrerAppareil(installationId: installation, jeton: nouveau, plateforme: AppConfig.plateforme)
            .catchError((Object _) {});
      });
      return ResultatPush.active;
    } catch (e) {
      debugPrint('[push] activation impossible : $e');
      return ResultatPush.indisponible;
    }
  }

  /// Retire ce téléphone des destinataires (déconnexion, désactivation). Ne lève jamais.
  Future<void> desactiver(DgFlowApi api) async {
    await _renouvellement?.cancel();
    _renouvellement = null;
    if (!_disponible) return;
    try {
      final installation = await coffre.lire(Cles.installation);
      if (installation != null) await api.supprimerAppareil(installation);
    } catch (_) {
      // La déconnexion serveur retire de toute façon les appareils de la session.
    }
  }
}
