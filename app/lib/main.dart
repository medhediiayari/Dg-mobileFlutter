import 'dart:async';
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app/app.dart';
import 'core/api/api_http.dart';
import 'core/auth/coffre.dart';
import 'core/config/app_config.dart';
import 'core/demo/api_demo.dart';
import 'core/providers.dart';
import 'core/push/service_push.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  Intl.defaultLocale = 'fr_FR';

  final Coffre coffre = AppConfig.demo ? CoffreMemoire() : CoffreSecurise();
  final infos = await _infosApp();
  // Firebase n'est pas encore configuré : sans google-services.json /
  // GoogleService-Info.plist, l'initialisation échoue et le push est désactivé.
  // Elle se fait en arrière-plan pour ne pas retarder l'ouverture.
  final push = ServicePush(coffre: coffre, initialiserFirebase: _initialiserFirebase);
  unawaited(push.demarrer());

  final api = AppConfig.demo ? ApiDemo() : ApiHttp.depuisConfig(coffre: coffre, versionApp: infos.version);

  runApp(
    ProviderScope(
      // Pas de nouvelle tentative automatique : chaque écran propose « Réessayer ».
      retry: (_, _) => null,
      overrides: [
        apiProvider.overrideWithValue(api),
        coffreProvider.overrideWithValue(coffre),
        infosAppProvider.overrideWithValue(infos),
        pushProvider.overrideWithValue(push),
      ],
      child: const DgFlowApp(),
    ),
  );
}

Future<InfosApp> _infosApp() async {
  var version = '1.0.0';
  var appareil = 'Téléphone';
  try {
    version = (await PackageInfo.fromPlatform()).version;
  } catch (_) {}
  try {
    if (!kIsWeb && Platform.isAndroid) {
      final a = await DeviceInfoPlugin().androidInfo;
      appareil = '${_majuscule(a.manufacturer)} ${a.model}'.trim();
    } else if (!kIsWeb && Platform.isIOS) {
      final i = await DeviceInfoPlugin().iosInfo;
      appareil = 'Apple ${i.modelName}'.trim();
    }
  } catch (_) {}
  return InfosApp(version: version, nomAppareil: appareil.length > 120 ? appareil.substring(0, 120) : appareil);
}

Future<bool> _initialiserFirebase() async {
  try {
    await Firebase.initializeApp();
    return true;
  } catch (e) {
    debugPrint('[push] Firebase indisponible, notifications désactivées : $e');
    return false;
  }
}

String _majuscule(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
