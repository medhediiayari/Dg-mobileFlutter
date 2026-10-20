import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/session.dart';
import '../dialogues.dart';
import '../theme.dart';
import 'composants.dart';

/// Feuille « Agir en tant que » — ouverte depuis l'accueil ou le profil.
Future<void> ouvrirSelecteurRole(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (_) => const _SelecteurRole(),
);

class _SelecteurRole extends ConsumerStatefulWidget {
  const _SelecteurRole();

  @override
  ConsumerState<_SelecteurRole> createState() => _SelecteurRoleState();
}

class _SelecteurRoleState extends ConsumerState<_SelecteurRole> {
  int? _enCours;

  Future<void> _choisir(int roleId, int actif) async {
    if (roleId == actif) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _enCours = roleId);
    try {
      await ref.read(sessionProvider.notifier).changerRole(roleId);
      unawaited(HapticFeedback.selectionClick());
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) await informer(context, 'Changement de rôle impossible', messageErreur(e));
    } finally {
      if (mounted) setState(() => _enCours = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profil = ref.watch(profilProvider);
    final p = context.dg;
    if (profil == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Espace.xl, 0, Espace.xl, Espace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.arrowLeftRight, size: 20, color: p.action),
              const SizedBox(width: Espace.s),
              Expanded(child: Text('Agir en tant que', style: Typo.titre.copyWith(color: p.titre))),
            ],
          ),
          const SizedBox(height: Espace.xs),
          Text(
            'La file « À traiter » et les décisions possibles dépendent du rôle choisi.',
            style: Typo.secondaire.copyWith(color: p.texteSecondaire),
          ),
          const SizedBox(height: Espace.l),
          for (final r in profil.roles)
            Padding(
              padding: const EdgeInsets.only(bottom: Espace.s),
              child: Builder(
                builder: (context) {
                  final actif = r.id == profil.roleActif.id;
                  return Semantics(
                    inMutuallyExclusiveGroup: true,
                    checked: actif,
                    child: Material(
                      color: actif ? p.accentClair : p.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Rayon.m),
                        side: BorderSide(color: actif ? p.action : p.bordure, width: actif ? 2 : 1),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(Rayon.m),
                        onTap: _enCours == null ? () => _choisir(r.id, profil.roleActif.id) : null,
                        child: Padding(
                          padding: const EdgeInsets.all(Espace.m),
                          child: Row(
                            children: [
                              // Sigle du rôle : actif comme l'élément de la sidebar (`bg-[#0061A7] text-white`).
                              Container(
                                constraints: const BoxConstraints(minWidth: 44),
                                height: 34,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: actif ? p.action : p.gris.fond,
                                  borderRadius: BorderRadius.circular(Rayon.s),
                                ),
                                child: Text(
                                  r.monogramme,
                                  style: Typo.sigle.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: actif ? p.surAction : p.texteSecondaire,
                                  ),
                                ),
                              ),
                              const SizedBox(width: Espace.m),
                              Expanded(
                                child: Text(
                                  r.libelle,
                                  style: Typo.corps.copyWith(
                                    fontWeight: actif ? FontWeight.w600 : FontWeight.w500,
                                    color: actif ? p.titre : p.texte,
                                  ),
                                ),
                              ),
                              if (_enCours == r.id)
                                const Roue(taille: 20)
                              else if (actif)
                                Icon(LucideIcons.checkCircle2, size: 20, color: p.action)
                              else
                                Icon(LucideIcons.circle, size: 20, color: p.texteDiscret),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
