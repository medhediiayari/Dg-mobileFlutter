import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/session.dart';
import '../../core/config/app_config.dart';
import '../../core/models/models.dart';
import '../../core/providers.dart';
import '../../core/push/service_push.dart';
import '../../core/utils/format.dart';
import '../../ui/dialogues.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/composants.dart';
import '../../ui/widgets/selecteur_role.dart';
import '../../ui/widgets/squelette.dart';
import '../rc/rc_providers.dart';

class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  bool _pushEnCours = false;
  bool _deconnexionEnCours = false;

  Future<void> _verifierPush() async {
    setState(() => _pushEnCours = true);
    final r = await ref.read(pushProvider).activer(ref.read(apiProvider));
    if (!mounted) return;
    setState(() => _pushEnCours = false);
    await informer(context, 'Notifications', switch (r) {
      ResultatPush.active => 'Les notifications sont activées sur ce téléphone.',
      ResultatPush.refusee => 'Autorisez les notifications pour DG Flow RC dans les réglages du téléphone.',
      ResultatPush.indisponible =>
        'Notifications indisponibles sur cette installation (Firebase non configuré ou service de notification injoignable).',
    });
  }

  Future<void> _desactiverPush() async {
    setState(() => _pushEnCours = true);
    await ref.read(pushProvider).desactiver(ref.read(apiProvider));
    if (!mounted) return;
    setState(() => _pushEnCours = false);
    signaler(
      context,
      'Ce téléphone ne recevra plus les notifications.',
      icone: LucideIcons.bellOff,
      teinte: context.dg.gris,
    );
  }

  Future<void> _deconnecter() async {
    final ok = await confirmer(
      context,
      titre: 'Se déconnecter ?',
      message: 'Ce téléphone ne recevra plus les notifications.',
      libelleOk: 'Se déconnecter',
      destructif: true,
    );
    if (!ok || !mounted) return;
    setState(() => _deconnexionEnCours = true);
    unawaited(HapticFeedback.mediumImpact());
    await ref.read(sessionProvider.notifier).deconnexion();
  }

  Future<void> _revoquer(SessionAppareil s) async {
    final ok = await confirmer(
      context,
      titre: 'Déconnecter cet appareil ?',
      message: '${s.appareil ?? 'Cet appareil'} devra se reconnecter pour accéder à DG Flow RC.',
      libelleOk: 'Déconnecter',
      destructif: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(apiProvider).revoquerSession(s.sid);
      ref.invalidate(sessionsAppareilsProvider);
      if (mounted) signaler(context, 'Appareil déconnecté.');
    } catch (e) {
      if (mounted) await informer(context, 'Déconnexion impossible', messageErreur(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final profil = ref.watch(profilProvider);
    final push = ref.watch(pushProvider);
    final apparence = ref.watch(apparenceProvider);
    final version = ref.watch(infosAppProvider).version;
    if (profil == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: false,
        titleSpacing: Espace.l,
        flexibleSpace: const DegradeEnTete(),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Espace.xxl),
        children: [
          _EnTete(profil: profil),
          Padding(
            padding: const EdgeInsets.fromLTRB(Espace.l, Espace.l, Espace.l, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section affichée seulement quand le push est disponible (Firebase configuré).
                ListenableBuilder(
                  listenable: push,
                  builder: (context, _) => !push.disponible
                      ? const SizedBox.shrink()
                      : Section(
                          titre: 'Notifications',
                          icone: LucideIcons.bell,
                          padding: const EdgeInsets.all(Espace.l),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Une alerte dès qu'un document arrive à votre étape ou vous est renvoyé.",
                                style: Typo.secondaire.copyWith(color: p.texteSecondaire),
                              ),
                              const SizedBox(height: Espace.m),
                              OutlinedButton.icon(
                                onPressed: _pushEnCours ? null : _verifierPush,
                                icon: _pushEnCours ? const Roue() : const Icon(LucideIcons.bellRing, size: 18),
                                label: const Text('Activer / vérifier les notifications'),
                              ),
                              TextButton(
                                onPressed: _pushEnCours ? null : _desactiverPush,
                                child: const Text('Ne plus recevoir sur ce téléphone'),
                              ),
                            ],
                          ),
                        ),
                ),
                _Appareils(onRevoquer: _revoquer),
                Section(
                  titre: 'Apparence',
                  icone: LucideIcons.sunMoon,
                  nu: true,
                  child: Segment<ThemeMode>(
                    options: const [
                      (ThemeMode.system, 'Système'),
                      (ThemeMode.light, 'Clair'),
                      (ThemeMode.dark, 'Sombre'),
                    ],
                    valeur: apparence,
                    onChange: (m) => ref.read(apparenceProvider.notifier).choisir(m),
                  ),
                ),
                Section(
                  titre: 'Application',
                  icone: LucideIcons.info,
                  child: Column(
                    children: [
                      LigneInfo(libelle: 'Version', valeur: version),
                      LigneInfo(libelle: 'Serveur', valeur: AppConfig.serveurAffiche, derniere: true),
                    ],
                  ),
                ),
                BoutonContour(
                  teinte: p.rouge,
                  libelle: _deconnexionEnCours ? 'Déconnexion…' : 'Se déconnecter',
                  icone: LucideIcons.logOut,
                  onPressed: _deconnexionEnCours ? null : _deconnecter,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau d'identité, comme le pied de la sidebar du web : nom `text-base
/// font-semibold text-white`, rôle `text-sm text-[#8BB1E0] font-medium`, puis le
/// bouton de changement de rôle (`RoleSwitcher` : `border-[#0061A7]/40 bg-[#0061A7]/30`).
class _EnTete extends StatelessWidget {
  const _EnTete({required this.profil});

  final Profil profil;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Marque.marine, Marque.marineDegrade])),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Espace.l, Espace.s, Espace.l, Espace.l + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // Avatar du web : `rounded-full bg-gradient-to-br from-[#4F8FCC] to-[#0061A7] text-white font-bold`.
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Marque.bleuMoyen, Marque.bleu],
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.20), width: 2),
                  ),
                  child: Text(profil.initiales, style: Typo.sousTitre.copyWith(color: Colors.white)),
                ),
                const SizedBox(width: Espace.m + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profil.nomComplet,
                        style: Typo.corps.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      Text(
                        profil.roleActif.libelle,
                        style: Typo.secondaire.copyWith(fontWeight: FontWeight.w500, color: p.surMarineDoux),
                      ),
                      Text(
                        profil.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Typo.petit.copyWith(
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Espace.m + 2),
            if (profil.plusieursRoles)
              Material(
                color: Marque.bleu.withValues(alpha: 0.30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Rayon.m),
                  side: BorderSide(color: Marque.bleu.withValues(alpha: 0.40)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(Rayon.m),
                  onTap: () => ouvrirSelecteurRole(context),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Espace.m),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.arrowLeftRight, size: 16, color: Colors.white),
                          const SizedBox(width: Espace.s),
                          Text('Changer', style: Typo.libelle.copyWith(color: Colors.white)),
                          const SizedBox(width: Espace.s),
                          Expanded(
                            child: Text(
                              '${profil.roles.length} rôles disponibles',
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Typo.petit.copyWith(color: p.surMarineDoux),
                            ),
                          ),
                          const SizedBox(width: Espace.xs),
                          Icon(LucideIcons.chevronRight, size: 16, color: p.surMarineDoux),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              Text(
                'Seul rôle du module RC sur votre compte',
                style: Typo.petit.copyWith(fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.6)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Appareils connectés (`/me/sessions`) : ce téléphone et les autres sessions.
class _Appareils extends ConsumerWidget {
  const _Appareils({required this.onRevoquer});

  final ValueChanged<SessionAppareil> onRevoquer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.dg;
    final etat = ref.watch(sessionsAppareilsProvider);
    return Section(
      titre: 'Appareils connectés',
      icone: LucideIcons.smartphone,
      padding: EdgeInsets.zero,
      child: switch (etat) {
        AsyncValue(:final value?) => Column(
          children: [
            for (final (i, s) in value.indexed)
              Container(
                padding: const EdgeInsets.fromLTRB(Espace.l, Espace.m, Espace.s, Espace.m),
                decoration: BoxDecoration(
                  border: i < value.length - 1 ? Border(bottom: BorderSide(color: p.bordure)) : null,
                ),
                child: Row(
                  children: [
                    CercleIcone(
                      teinte: s.courante ? p.bleu : p.gris,
                      icone: s.plateforme == 'ios' || s.plateforme == 'android'
                          ? LucideIcons.smartphone
                          : LucideIcons.monitor,
                      taille: 36,
                      tailleIcone: 18,
                    ),
                    const SizedBox(width: Espace.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.appareil ?? 'Appareil inconnu', style: Typo.libelle.copyWith(color: p.texte)),
                          Text(
                            s.courante ? 'Ce téléphone' : 'Dernière activité ${Format.relatif(s.utiliseLe)}',
                            style: Typo.secondaire.copyWith(
                              color: s.courante ? p.emeraude.vif : p.texteSecondaire,
                              fontWeight: s.courante ? FontWeight.w500 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!s.courante)
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: p.rouge.vif),
                        onPressed: () => onRevoquer(s),
                        child: const Text('Déconnecter'),
                      ),
                  ],
                ),
              ),
          ],
        ),
        AsyncValue(:final error?) => Padding(
          padding: const EdgeInsets.all(Espace.l),
          child: Row(
            children: [
              Expanded(
                child: Text(messageErreur(error), style: Typo.secondaire.copyWith(color: p.texteSecondaire)),
              ),
              TextButton(onPressed: () => ref.invalidate(sessionsAppareilsProvider), child: const Text('Réessayer')),
            ],
          ),
        ),
        _ => const Miroitement(
          child: Padding(
            padding: EdgeInsets.all(Espace.l),
            child: Column(children: [Os(facteur: 1, hauteur: 16), SizedBox(height: 12), Os(facteur: 0.7, hauteur: 16)]),
          ),
        ),
      },
    );
  }
}
