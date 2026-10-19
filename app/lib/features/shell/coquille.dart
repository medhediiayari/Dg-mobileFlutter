import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ui/theme.dart';
import '../rc/rc_providers.dart';

/// Barre d'onglets : À traiter, Suivi, Alertes (pastille des non-lues), Profil.
class Coquille extends ConsumerWidget {
  const Coquille({required this.navigation, super.key});

  final StatefulNavigationShell navigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.dg;
    final nonLues = ref.watch(nonLuesProvider).value ?? 0;
    return Scaffold(
      body: navigation,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: p.bordure)),
        ),
        child: NavigationBar(
          selectedIndex: navigation.currentIndex,
          onDestinationSelected: (i) {
            unawaited(HapticFeedback.selectionClick());
            navigation.goBranch(i, initialLocation: i == navigation.currentIndex);
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              selectedIcon: Icon(Icons.inbox_rounded),
              label: 'À traiter',
            ),
            const NavigationDestination(
              icon: Icon(Icons.account_tree_outlined),
              selectedIcon: Icon(Icons.account_tree_rounded),
              label: 'Suivi',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: nonLues > 0,
                label: Text(nonLues > 99 ? '99+' : '$nonLues'),
                child: const Icon(Icons.notifications_none_rounded),
              ),
              selectedIcon: Badge(
                isLabelVisible: nonLues > 0,
                label: Text(nonLues > 99 ? '99+' : '$nonLues'),
                child: const Icon(Icons.notifications_rounded),
              ),
              label: 'Alertes',
              tooltip: nonLues > 0 ? 'Alertes, $nonLues non lues' : 'Alertes',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
