import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/coffre.dart';
import '../../core/auth/microsoft.dart';
import '../../core/auth/session.dart';
import '../../core/config/app_config.dart';
import '../../core/providers.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/composants.dart';
import '../../ui/widgets/marque.dart';

/// Page de connexion du web (`dgflow/app/page.tsx`) : visuel des bureaux flouté
/// sous un voile marine avec le logo DG Group, puis le formulaire sur fond blanc.
class ConnexionScreen extends ConsumerStatefulWidget {
  const ConnexionScreen({super.key});

  @override
  ConsumerState<ConnexionScreen> createState() => _ConnexionScreenState();
}

class _ConnexionScreenState extends ConsumerState<ConnexionScreen> {
  final _email = TextEditingController();
  final _motDePasse = TextEditingController();
  final _focusMdp = FocusNode();
  bool _visible = false;
  bool _enCours = false;
  bool _enCoursMicrosoft = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    ref.read(coffreProvider).lire(Cles.dernierEmail).then((e) {
      if (e != null && mounted && _email.text.isEmpty) _email.text = e;
    });
    if (AppConfig.demo) {
      _email.text = 'camille.lefevre@dggroup.fr';
      _motDePasse.text = 'demo';
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _motDePasse.dispose();
    _focusMdp.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    if (_email.text.trim().isEmpty || _motDePasse.text.isEmpty) {
      setState(() => _erreur = 'Saisissez votre email et votre mot de passe.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _erreur = null;
      _enCours = true;
    });
    try {
      await ref.read(sessionProvider.notifier).connexion(_email.text, _motDePasse.text);
      unawaited(HapticFeedback.lightImpact());
    } catch (e) {
      if (mounted) setState(() => _erreur = messageErreur(e));
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _microsoft() async {
    final config = ref.read(sessionProvider).meta?.microsoft;
    if (config == null) return;
    setState(() {
      _erreur = null;
      _enCoursMicrosoft = true;
    });
    try {
      final jeton = await ref.read(microsoftProvider).jetonGraph(config);
      if (jeton != null) await ref.read(sessionProvider.notifier).connexionMicrosoft(jeton);
    } on ErreurMicrosoft catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } catch (e) {
      if (mounted) setState(() => _erreur = messageErreur(e));
    } finally {
      if (mounted) setState(() => _enCoursMicrosoft = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final meta = ref.watch(sessionProvider.select((s) => s.meta));
    final version = ref.watch(infosAppProvider).version;
    final occupe = _enCours || _enCoursMicrosoft;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.surface,
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Visuel(),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Espace.xl, Espace.xxl, Espace.xl, Espace.xl),
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // `text-5xl font-bold text-foreground` puis `text-muted-foreground text-base`.
                          Semantics(
                            header: true,
                            child: Text(
                              'Bienvenue',
                              textAlign: TextAlign.center,
                              style: Typo.affiche.copyWith(fontSize: 36, height: 1.15, color: p.texte),
                            ),
                          ),
                          const SizedBox(height: Espace.s),
                          Text(
                            'Connectez-vous à votre compte DG Flow',
                            textAlign: TextAlign.center,
                            style: Typo.corps.copyWith(color: p.texteSecondaire),
                          ),
                          const SizedBox(height: Espace.xxl),
                          const _Libelle('Adresse e-mail'),
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username, AutofillHints.email],
                            style: Typo.corps.copyWith(fontSize: 16, color: p.texte),
                            decoration: const InputDecoration(hintText: 'prenom.nom@dggroup.fr'),
                            onSubmitted: (_) => _focusMdp.requestFocus(),
                          ),
                          const SizedBox(height: Espace.l),
                          const _Libelle('Mot de passe'),
                          TextField(
                            controller: _motDePasse,
                            focusNode: _focusMdp,
                            obscureText: !_visible,
                            textInputAction: TextInputAction.go,
                            autofillHints: const [AutofillHints.password],
                            onSubmitted: (_) => _valider(),
                            style: Typo.corps.copyWith(fontSize: 16, color: p.texte),
                            decoration: InputDecoration(
                              hintText: 'Votre mot de passe',
                              suffixIcon: IconButton(
                                tooltip: _visible ? 'Masquer le mot de passe' : 'Afficher le mot de passe',
                                icon: Icon(
                                  _visible ? LucideIcons.eyeOff : LucideIcons.eye,
                                  size: 18,
                                  color: p.texteSecondaire,
                                ),
                                onPressed: () => setState(() => _visible = !_visible),
                              ),
                            ),
                          ),
                          const SizedBox(height: Espace.l),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            child: _erreur == null
                                ? const SizedBox(width: double.infinity)
                                : EncartErreur(message: _erreur!),
                          ),
                          const SizedBox(height: Espace.s),
                          // `w-full h-12 text-base font-semibold`, `#0061A7`.
                          FilledButton(
                            onPressed: occupe ? null : _valider,
                            style: FilledButton.styleFrom(
                              textStyle: Typo.bouton.copyWith(fontSize: 16),
                              disabledBackgroundColor: _enCours ? p.action : null,
                              disabledForegroundColor: _enCours ? p.surAction : null,
                            ),
                            child: _enCours
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Roue(couleur: p.surAction, taille: 16),
                                      const SizedBox(width: Espace.s),
                                      const Text('Connexion...'),
                                    ],
                                  )
                                : const Text('Se connecter'),
                          ),
                          if (meta?.microsoft != null) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: Espace.l + 4),
                              child: Row(
                                children: [
                                  Expanded(child: Divider(color: p.bordure)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: Espace.m),
                                    child: Text(
                                      'OU',
                                      style: Typo.petit.copyWith(color: p.texteSecondaire, letterSpacing: 0.4),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: p.bordure)),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: occupe ? null : _microsoft,
                              style: OutlinedButton.styleFrom(textStyle: Typo.libelle),
                              icon: _enCoursMicrosoft ? const Roue(taille: 16) : const _IconeMicrosoft(),
                              label: const Text('Se connecter avec DG Group'),
                            ),
                          ],
                          const SizedBox(height: Espace.l),
                          Text(
                            AppConfig.demo
                                ? 'Mode démonstration : n’importe quel email et mot de passe ouvrent une session fictive.'
                                : 'Mêmes identifiants que DG Flow web. Mot de passe oublié : utilisez « Mot de passe oublié » sur DG Flow web.',
                            textAlign: TextAlign.center,
                            style: Typo.petit.copyWith(color: p.texteSecondaire, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: Espace.xl),
                          // Pied de page : `pt-8 border-t border-gray-100`, `text-xs text-muted-foreground`.
                          Container(
                            padding: const EdgeInsets.only(top: Espace.l),
                            decoration: BoxDecoration(border: Border(top: BorderSide(color: p.gris.fond))),
                            child: Column(
                              children: [
                                Text(
                                  '© 2026 DG Group. Tous droits réservés.',
                                  textAlign: TextAlign.center,
                                  style: Typo.petit.copyWith(color: p.texteSecondaire, fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: Espace.xs),
                                Text(
                                  'Version $version, serveur ${AppConfig.serveurAffiche}',
                                  textAlign: TextAlign.center,
                                  style: Typo.petit.copyWith(color: p.texteTertiaire, fontWeight: FontWeight.w400),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panneau visuel du web : `dg-office-background.jpg` flouté (`blur(4px)`), voile
/// `rgb(23 45 76 / 48%)`, logo DG Group, « Bienvenue sur DG Flow ».
class _Visuel extends StatelessWidget {
  const _Visuel();

  @override
  Widget build(BuildContext context) {
    final haut = MediaQuery.paddingOf(context).top;
    return ClipRect(
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4, tileMode: TileMode.clamp),
              child: Image.asset(
                'assets/images/dg-office-background.jpg',
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
          ),
          Positioned.fill(child: ColoredBox(color: Marque.marine.withValues(alpha: 0.48))),
          Padding(
            padding: EdgeInsets.fromLTRB(Espace.xl, haut + Espace.xl, Espace.xl, Espace.xl + 4),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/dg-group-logo.png',
                  width: 120,
                  semanticLabel: 'DG Group',
                ),
                const SizedBox(height: Espace.l),
                Text(
                  'Bienvenue sur DG Flow',
                  textAlign: TextAlign.center,
                  style: Typo.affiche.copyWith(fontSize: 26, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: Espace.xs),
                Text(
                  'Votre plateforme de gestion de projets',
                  textAlign: TextAlign.center,
                  style: Typo.corps.copyWith(fontSize: 16, color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: Espace.m),
                // Module de l'application, en tuile du bandeau marine (`bg-white/10 border-white/20`).
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Espace.m, vertical: Espace.xs),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('Parcours RC', style: Typo.libelle.copyWith(color: Colors.white)),
                ),
                if (AppConfig.demo) ...[const SizedBox(height: Espace.m), const BandeauDemo()],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Libelle extends StatelessWidget {
  const _Libelle(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Espace.s),
    child: Text(texte, style: Typo.libelle.copyWith(color: context.dg.texte)),
  );
}

/// Les quatre carrés Microsoft du bouton du web (couleurs de la marque Microsoft).
class _IconeMicrosoft extends StatelessWidget {
  const _IconeMicrosoft();

  @override
  Widget build(BuildContext context) {
    Widget carre(Color c) => Container(width: 8.5, height: 8.5, color: c);
    return Container(
      width: 20,
      height: 20,
      color: const Color(0xFFF3F3F3),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [carre(const Color(0xFFF35325)), const SizedBox(width: 1), carre(const Color(0xFF81BC06))],
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [carre(const Color(0xFF05A6F0)), const SizedBox(width: 1), carre(const Color(0xFFFFBA08))],
          ),
        ],
      ),
    );
  }
}
