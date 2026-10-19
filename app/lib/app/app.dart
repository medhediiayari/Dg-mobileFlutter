import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/session.dart';
import '../core/providers.dart';
import '../core/push/service_push.dart';
import '../features/rc/rc_providers.dart';
import '../ui/theme.dart';
import 'routeur.dart';

class DgFlowApp extends ConsumerStatefulWidget {
  const DgFlowApp({super.key});

  @override
  ConsumerState<DgFlowApp> createState() => _DgFlowAppState();
}

class _DgFlowAppState extends ConsumerState<DgFlowApp> {
  StreamSubscription<OuverturePush>? _abonnement;
  OuverturePush? _enAttente;

  @override
  void initState() {
    super.initState();
    final push = ref.read(pushProvider);
    _abonnement = push.ouvertures.listen(_ouvrir);
    _enAttente = push.prendreEnAttente();
    // Toucher une notification ouvre le document, dès que la session est prête.
    ref.listenManual(sessionProvider.select((s) => s.etat), (_, etat) {
      if (etat == EtatSession.connecte && _enAttente != null) {
        final o = _enAttente!;
        _enAttente = null;
        WidgetsBinding.instance.addPostFrameCallback((_) => _ouvrir(o));
      }
    });
  }

  void _ouvrir(OuverturePush o) {
    if (ref.read(sessionProvider).etat != EtatSession.connecte) {
      _enAttente = o;
      return;
    }
    final api = ref.read(apiProvider);
    if (o.notificationId != null) {
      api.marquerLue(o.notificationId!).then((_) => ref.invalidate(notificationsProvider)).catchError((Object _) {});
    }
    ref.invalidate(nonLuesProvider);
    final routeur = ref.read(routeurProvider);
    if (o.rcId != null) {
      routeur.push('/rc/${o.rcId}');
    } else {
      routeur.go('/alertes');
    }
  }

  @override
  void dispose() {
    _abonnement?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DG Flow RC',
      debugShowCheckedModeBanner: false,
      theme: construireTheme(Brightness.light),
      darkTheme: construireTheme(Brightness.dark),
      themeMode: ref.watch(apparenceProvider),
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routeurProvider),
    );
  }
}
