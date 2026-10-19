import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    signaler(context, 'Ce téléphone ne recevra plus les notifications.', icone: Icons.notifications_off_outlined);
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
      if (mounted) signaler(context, 'Appareil déconnecté.', icone: Icons.check_rounded);
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
    final r = profil.roleActif;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil'), automaticallyImplyLeading: false, titleSpacing: Espace.l),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Espace.l, Espace.l, Espace.l, Espace.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: Espace.xl),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: p.marine, shape: BoxShape.circle),
                  child: Text(profil.initiales, style: Typo.titre.copyWith(color: Colors.white)),
                ),
                const SizedBox(width: Espace.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profil.nomComplet, style: Typo.titre.copyWith(color: p.texte)),
                      Text(profil.email, style: Typo.secondaire.copyWith(color: p.texteSecondaire)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Section(
            titre: 'Rôle actif',
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: profil.plusieursRoles ? () => ouvrirSelecteurRole(context) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(Espace.l),
                    child: Row(
                      children: [
                        Container(
                          constraints: const BoxConstraints(minWidth: 50),
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.chevronProfond,
                            borderRadius: BorderRadius.circular(Rayon.s),
                          ),
                          child: Text(r.monogramme, style: Typo.sigle.copyWith(fontSize: 16, color: Colors.white)),
                        ),
                        const SizedBox(width: Espace.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.libelle, style: Typo.corpsFort.copyWith(color: p.texte)),
                              Text(
                                profil.plusieursRoles
                                    ? '${profil.roles.length} rôles disponibles'
                                    : 'Seul rôle du module RC sur votre compte',
                                style: Typo.secondaire.copyWith(color: p.texteSecondaire),
                              ),
                            ],
                          ),
                        ),
                        if (profil.plusieursRoles) Text('Changer', style: Typo.libelle.copyWith(color: p.action)),
                      ],
                    ),
                  ),
                ),
                if (profil.motifLectureSeule != null)
                  Container(
                    padding: const EdgeInsets.all(Espace.l),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: p.bordure)),
                    ),
                    child: Text(profil.motifLectureSeule!, style: Typo.secondaire.copyWith(color: p.texteSecondaire)),
                  ),
              ],
            ),
          ),
          Section(
            titre: 'Notifications',
            padding: const EdgeInsets.all(Espace.l),
            child: ListenableBuilder(
              listenable: push,
              builder: (context, _) => push.disponible
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Une alerte dès qu'un document arrive à votre étape ou vous est renvoyé.",
                          style: Typo.secondaire.copyWith(color: p.texteSecondaire),
                        ),
                        const SizedBox(height: Espace.m),
                        OutlinedButton.icon(
                          onPressed: _pushEnCours ? null : _verifierPush,
                          icon: _pushEnCours ? const Roue() : const Icon(Icons.notifications_active_outlined),
                          label: const Text('Activer / vérifier les notifications'),
                        ),
                        TextButton(
                          onPressed: _pushEnCours ? null : _desactiverPush,
                          child: const Text('Ne plus recevoir sur ce téléphone'),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notifications_off_outlined, color: p.texteTertiaire),
                        const SizedBox(width: Espace.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Notifications non configurées', style: Typo.corpsFort.copyWith(color: p.texte)),
                              Text(
                                'Firebase n’est pas encore configuré pour cette version : consultez l’onglet Alertes, '
                                'il reste à jour.',
                                style: Typo.secondaire.copyWith(color: p.texteSecondaire),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          _Appareils(onRevoquer: _revoquer),
          Section(
            titre: 'Apparence',
            nu: true,
            child: Segment<ThemeMode>(
              options: const [(ThemeMode.system, 'Système'), (ThemeMode.light, 'Clair'), (ThemeMode.dark, 'Sombre')],
              valeur: apparence,
              onChange: (m) => ref.read(apparenceProvider.notifier).choisir(m),
            ),
          ),
          Section(
            titre: 'Application',
            child: Column(
              children: [
                LigneInfo(libelle: 'Version', valeur: version),
                LigneInfo(libelle: 'Serveur', valeur: AppConfig.serveurAffiche, derniere: true),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: p.danger),
              onPressed: _deconnexionEnCours ? null : _deconnecter,
              icon: _deconnexionEnCours ? Roue(couleur: p.danger) : const Icon(Icons.logout_rounded),
              label: const Text('Se déconnecter'),
            ),
          ),
        ],
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
                    Icon(
                      s.plateforme == 'ios' || s.plateforme == 'android'
                          ? Icons.smartphone_rounded
                          : Icons.computer_rounded,
                      color: s.courante ? p.action : p.texteSecondaire,
                    ),
                    const SizedBox(width: Espace.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.appareil ?? 'Appareil inconnu', style: Typo.corpsFort.copyWith(color: p.texte)),
                          Text(
                            s.courante ? 'Ce téléphone' : 'Dernière activité ${Format.relatif(s.utiliseLe)}',
                            style: Typo.secondaire.copyWith(color: s.courante ? p.succes : p.texteSecondaire),
                          ),
                        ],
                      ),
                    ),
                    if (!s.courante)
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: p.danger),
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
