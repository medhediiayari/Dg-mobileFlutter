import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/session.dart';
import '../../core/config/app_config.dart';
import '../../core/providers.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/composants.dart';
import '../../ui/widgets/marque.dart';

/// Serveur injoignable au démarrage, ou version de l'application trop ancienne.
class IndisponibleScreen extends ConsumerWidget {
  const IndisponibleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionProvider);
    final version = ref.watch(infosAppProvider).version;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: Espace.xxl),
              child: LogoDgFlow(hauteur: 34),
            ),
            Expanded(
              child: s.etat == EtatSession.miseAJour
                  ? EtatVide(
                      icone: Icons.system_update_rounded,
                      titre: 'Mise à jour requise',
                      texte:
                          "Cette version de l'application ($version) n'est plus acceptée (minimum ${s.meta?.versionMinimaleApp}). "
                          'Installez la dernière version depuis le store ou le lien de distribution interne.',
                    )
                  : EtatErreur(
                      message: '${s.erreurDemarrage ?? 'Serveur injoignable.'}\n\n${AppConfig.apiUrl}',
                      onReessayer: () => ref.read(sessionProvider.notifier).demarrer(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Écran de démarrage : le temps de lire /meta et la session.
class DemarrageScreen extends StatelessWidget {
  const DemarrageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LogoDgFlow(hauteur: 40),
            const SizedBox(height: Espace.xl),
            SizedBox(
              width: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(minHeight: 3, color: p.chevronMoyen, backgroundColor: p.chevronVide),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
