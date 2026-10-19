import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/coffre.dart';
import '../../core/auth/microsoft.dart';
import '../../core/auth/session.dart';
import '../../core/config/app_config.dart';
import '../../core/providers.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/composants.dart';
import '../../ui/widgets/marque.dart';

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

    final haut = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête marine : la marque et le module, comme l'accueil.
              Container(
                decoration: BoxDecoration(
                  color: p.marine,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Rayon.xl + 6)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    const Positioned.fill(child: ChevronsFiligrane()),
                    Padding(
                      padding: EdgeInsets.fromLTRB(Espace.xl, haut + Espace.xl, Espace.xl, 76),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LogoDgFlow(hauteur: 30, surFonce: true),
                          const SizedBox(height: Espace.xxl + 8),
                          Semantics(
                            header: true,
                            child: Text('Parcours RC', style: Typo.affiche.copyWith(color: p.surMarine, fontSize: 36)),
                          ),
                          const SizedBox(height: Espace.xs),
                          Text(
                            'Approuvez, renvoyez et suivez les RC et avenants de vos chantiers.',
                            style: Typo.corps.copyWith(color: p.surMarineDoux),
                          ),
                          if (AppConfig.demo) ...[const SizedBox(height: Espace.m), const BandeauDemo()],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Transform.translate(
                    offset: const Offset(0, -52),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Espace.l),
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Carte(
                              padding: const EdgeInsets.all(Espace.xl),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _Libelle('Email professionnel'),
                                  TextField(
                                    controller: _email,
                                    keyboardType: TextInputType.emailAddress,
                                    autocorrect: false,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.username, AutofillHints.email],
                                    decoration: const InputDecoration(hintText: 'prenom.nom@dggroup.fr'),
                                    onSubmitted: (_) => _focusMdp.requestFocus(),
                                  ),
                                  const SizedBox(height: Espace.l),
                                  _Libelle('Mot de passe'),
                                  TextField(
                                    controller: _motDePasse,
                                    focusNode: _focusMdp,
                                    obscureText: !_visible,
                                    textInputAction: TextInputAction.go,
                                    autofillHints: const [AutofillHints.password],
                                    onSubmitted: (_) => _valider(),
                                    decoration: InputDecoration(
                                      hintText: '••••••••',
                                      suffixIcon: IconButton(
                                        tooltip: _visible ? 'Masquer le mot de passe' : 'Afficher le mot de passe',
                                        icon: Icon(
                                          _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
                                  FilledButton(
                                    onPressed: _enCours || _enCoursMicrosoft ? null : _valider,
                                    child: _enCours
                                        ? const SizedBox.square(
                                            dimension: 22,
                                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                          )
                                        : const Text('Se connecter'),
                                  ),
                                  if (meta?.microsoft != null) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: Espace.l),
                                      child: Row(
                                        children: [
                                          Expanded(child: Divider(color: p.bordure)),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: Espace.m),
                                            child: Text(
                                              'ou',
                                              style: Typo.secondaire.copyWith(color: p.texteSecondaire),
                                            ),
                                          ),
                                          Expanded(child: Divider(color: p.bordure)),
                                        ],
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: _enCours || _enCoursMicrosoft ? null : _microsoft,
                                      icon: _enCoursMicrosoft
                                          ? const SizedBox.square(
                                              dimension: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2.2),
                                            )
                                          : const _IconeMicrosoft(),
                                      label: const Text('Se connecter avec DG Group'),
                                    ),
                                  ],
                                  const SizedBox(height: Espace.l),
                                  Text(
                                    AppConfig.demo
                                        ? 'Mode démonstration : n’importe quel email et mot de passe ouvrent une session fictive.'
                                        : 'Mêmes identifiants que DG Flow web. Mot de passe oublié : utilisez « Mot de passe oublié » sur DG Flow web.',
                                    textAlign: TextAlign.center,
                                    style: Typo.petit.copyWith(color: p.texteSecondaire),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: Espace.xl),
                            Text(
                              'Version $version, serveur ${AppConfig.serveurAffiche}',
                              textAlign: TextAlign.center,
                              style: Typo.petit.copyWith(color: p.texteTertiaire, fontWeight: FontWeight.w400),
                            ),
                          ],
                        ),
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

class _Libelle extends StatelessWidget {
  const _Libelle(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Espace.xs + 2),
    child: Text(texte, style: Typo.libelle.copyWith(color: context.dg.texte)),
  );
}

/// Les quatre carrés Microsoft, dessinés (pas de dépendance d'icônes de marque).
class _IconeMicrosoft extends StatelessWidget {
  const _IconeMicrosoft();

  @override
  Widget build(BuildContext context) {
    Widget carre(Color c) => Container(width: 8, height: 8, color: c);
    return SizedBox.square(
      dimension: 18,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [carre(const Color(0xFFF25022)), const SizedBox(width: 1.5), carre(const Color(0xFF7FBA00))],
          ),
          const SizedBox(height: 1.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [carre(const Color(0xFF00A4EF)), const SizedBox(width: 1.5), carre(const Color(0xFFFFB900))],
          ),
        ],
      ),
    );
  }
}
