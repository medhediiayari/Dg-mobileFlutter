import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../ui/theme.dart';
import '../rc/rc_providers.dart';

/// Barre d'onglets : À traiter, Suivi, Alertes (pastille des non-lues), Profil.
/// Elle reprend la sidebar du web (`bg-[#172D4C]`, actif `bg-[#0061A7] text-white`,
/// inactif `text-[#8BB1E0]`, compteur `bg-red-500`) via `navigationBarTheme`.
class Coquille extends ConsumerWidget {
  const Coquille({required this.navigation, super.key});

  final StatefulNavigationShell navigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.dg;
    final nonLues = ref.watch(nonLuesProvider).value ?? 0;
    Widget cloche() => Badge(
      isLabelVisible: nonLues > 0,
      label: Text(nonLues > 99 ? '99+' : '$nonLues'),
      child: const Icon(LucideIcons.bell),
    );
    return Scaffold(
      body: navigation,
      bottomNavigationBar: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          systemNavigationBarColor: p.marine,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: NavigationBar(
          selectedIndex: navigation.currentIndex,
          onDestinationSelected: (i) {
            unawaited(HapticFeedback.selectionClick());
            navigation.goBranch(i, initialLocation: i == navigation.currentIndex);
          },
          destinations: [
            const NavigationDestination(icon: Icon(LucideIcons.inbox), label: 'À traiter'),
            const NavigationDestination(icon: Icon(LucideIcons.route), label: 'Suivi'),
            NavigationDestination(
              icon: cloche(),
              label: 'Alertes',
              tooltip: nonLues > 0 ? 'Alertes, $nonLues non lues' : 'Alertes',
            ),
            const NavigationDestination(icon: Icon(LucideIcons.userRound), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}
