import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    final p = context.dg;
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
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(Espace.xxl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CercleIcone(teinte: p.bleu, icone: LucideIcons.circleArrowUp, taille: 64, tailleIcone: 28),
                            const SizedBox(height: Espace.l),
                            Semantics(
                              header: true,
                              child: Text(
                                'Mise à jour requise',
                                textAlign: TextAlign.center,
                                style: Typo.sousTitre.copyWith(color: p.titre),
                              ),
                            ),
                            const SizedBox(height: Espace.s),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 340),
                              child: Text(
                                "Cette version de l'application ($version) n'est plus acceptée (minimum ${s.meta?.versionMinimaleApp}). "
                                'Installez la dernière version depuis le store ou le lien de distribution interne.',
                                textAlign: TextAlign.center,
                                style: Typo.secondaire.copyWith(color: p.texteSecondaire),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : EtatErreur(
                      icone: LucideIcons.cloudOff,
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
                child: LinearProgressIndicator(minHeight: 3, color: p.action, backgroundColor: p.bordure),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
