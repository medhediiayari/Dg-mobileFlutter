import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/models/models.dart';
import '../../../core/providers.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/parcours.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/composants.dart';
import '../../../ui/widgets/fil_parcours.dart';
import '../rc_providers.dart';
import 'choix_pieces.dart';

enum ModeDecision { approuver, rejeter, info, reponse, bc, annulerBc }

enum _Etape { saisie, decision, pieces, termine }

/// Ouvre la feuille de décision (approuver, rejeter / renvoyer, demande ou
/// réponse d'information, bon de commande) — l'équivalent des dialogues web.
Future<void> ouvrirDecision(
  BuildContext context,
  Detail d,
  ModeDecision mode, {
  required VoidCallback ouvrirTableau,
}) async {
  unawaited(HapticFeedback.selectionClick());
  final suite = await showModalBottomSheet<_Suite>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => FeuilleDecision(d: d, mode: mode),
  );
  if (suite == _Suite.ouvrirTableau) ouvrirTableau();
}

enum _Suite { relire, ouvrirTableau }

class FeuilleDecision extends ConsumerStatefulWidget {
  const FeuilleDecision({required this.d, required this.mode, super.key});

  final Detail d;
  final ModeDecision mode;

  @override
  ConsumerState<FeuilleDecision> createState() => _FeuilleDecisionState();
}

class _FeuilleDecisionState extends ConsumerState<FeuilleDecision> {
  late final ProviderContainer _conteneur;
  final _texte = TextEditingController();
  late int? _destinataire;
  List<PieceLocale> _pieces = [];
  _Etape _etape = _Etape.saisie;
  ApiException? _erreurApi;
  String? _erreur;
  double? _progression;
  String? _message;
  String? _avertissement;
  String? _statutFinal;
  bool _champEnErreur = false;

  ModeDecision get mode => widget.mode;
  Detail get d => widget.d;

  List<Destinataire> get _destinataires => switch (mode) {
    ModeDecision.rejeter => d.actions.destinatairesRenvoi,
    ModeDecision.info => d.actions.destinatairesInfo,
    _ => const [],
  };

  bool get _avecDestinataire =>
      mode == ModeDecision.info || (mode == ModeDecision.rejeter && d.actions.rejetAvecDestinataire);
  bool get _avecTexte =>
      const {ModeDecision.approuver, ModeDecision.rejeter, ModeDecision.info, ModeDecision.reponse}.contains(mode);
  bool get _signatureRequise => mode == ModeDecision.approuver || mode == ModeDecision.bc;
  bool get _bloqueSignature => _signatureRequise && d.actions.signatureManquante;

  String get _titre => switch (mode) {
    ModeDecision.approuver => 'Approuver et signer',
    ModeDecision.rejeter => d.actions.rejetAvecDestinataire ? 'Renvoyer' : 'Rejeter',
    ModeDecision.info => "Demande d'information",
    ModeDecision.reponse => 'Répondre',
    ModeDecision.bc => 'Convertir en Bon de Commande',
    ModeDecision.annulerBc => 'Annuler le Bon de Commande',
  };

  @override
  void initState() {
    super.initState();
    _conteneur = ProviderScope.containerOf(context, listen: false);
    final propose = d.actions.destinatairePropose;
    _destinataire = propose != null && _destinataires.any((x) => x.id == propose) ? propose : null;
  }

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final texte = _texte.text.trim();
    setState(() {
      _erreur = null;
      _erreurApi = null;
    });
    if (mode == ModeDecision.rejeter && texte.length < 3) {
      setState(() {
        _erreur = 'Indiquez le motif du rejet (3 caractères minimum).';
        _champEnErreur = true;
      });
      return;
    }
    if (mode == ModeDecision.info && texte.length < 3) {
      setState(() {
        _erreur = "Précisez l'information demandée (3 caractères minimum).";
        _champEnErreur = true;
      });
      return;
    }
    if (mode == ModeDecision.reponse && texte.isEmpty) {
      setState(() {
        _erreur = 'Le message est requis.';
        _champEnErreur = true;
      });
      return;
    }
    if (_avecDestinataire && _destinataire == null) {
      setState(() => _erreur = 'Choisissez un destinataire.');
      return;
    }

    FocusScope.of(context).unfocus();
    unawaited(HapticFeedback.lightImpact());
    setState(() => _etape = _Etape.decision);
    final api = _conteneur.read(apiProvider);
    try {
      final r = switch (mode) {
        ModeDecision.approuver => await api.approuver(d.id, commentaire: texte.isEmpty ? null : texte),
        ModeDecision.rejeter => await api.rejeter(d.id, motif: texte, destinataireId: _destinataire),
        ModeDecision.info => await api.demanderInfo(d.id, destinataireId: _destinataire!, message: texte),
        ModeDecision.reponse => await api.repondreInfo(d.id, message: texte),
        ModeDecision.bc => await api.bonDeCommande(d.id, actif: true),
        ModeDecision.annulerBc => await api.bonDeCommande(d.id, actif: false),
      };
      var message = r.message;
      String? avertissement;
      // Deux temps, comme le web : la décision est enregistrée, puis les pièces s'y rattachent.
      if (_pieces.isNotEmpty && r.evenementId != null) {
        if (mounted) setState(() => _etape = _Etape.pieces);
        try {
          await api.envoyerPieces(
            d.id,
            r.evenementId!,
            _pieces,
            progression: (fait, total) {
              if (mounted) setState(() => _progression = total > 0 ? fait / total : null);
            },
          );
          message = '$message — ${Format.pluriel(_pieces.length, 'pièce jointe', 'pièces jointes')}';
        } catch (e) {
          avertissement = "La décision est enregistrée, mais l'envoi des pièces jointes a échoué : ${messageErreur(e)}";
        }
      }
      invaliderApresDecision(_conteneur);
      if (avertissement != null) {
        unawaited(HapticFeedback.vibrate());
      } else {
        unawaited(HapticFeedback.heavyImpact());
      }
      if (mounted) {
        setState(() {
          _etape = _Etape.termine;
          _message = message;
          _avertissement = avertissement;
          _statutFinal = r.statut.isEmpty ? null : r.statut;
        });
      }
    } on ApiException catch (e) {
      unawaited(HapticFeedback.vibrate());
      // Comme le RN : la fiche est relue après chaque tentative (garde, statut,
      // signature ou paiement ont pu changer depuis l'ouverture).
      invaliderApresDecision(_conteneur);
      if (mounted) {
        setState(() {
          _etape = _Etape.saisie;
          _erreurApi = e;
        });
      }
    } catch (e) {
      unawaited(HapticFeedback.vibrate());
      if (mounted) {
        setState(() {
          _etape = _Etape.saisie;
          _erreur = messageErreur(e);
        });
      }
    }
  }

  /// Message et geste adaptés au code d'erreur de l'API.
  Widget _encartApi(ApiException e) {
    final p = context.dg;
    String message = e.message;
    Widget? action;
    switch (e.code) {
      case 'CONSULTATION_REQUISE' || 'CONSULTATION_PERIMEE':
        message = '${e.message} Revenez à la fiche pour le relire.';
        action = TextButton(
          onPressed: () => Navigator.of(context).pop(_Suite.relire),
          child: const Text('Relire la fiche'),
        );
      case 'CONSULTATION_TABLEAU_REQUISE':
        message = '${e.message} Revenez à la fiche pour le relire.';
        action = TextButton(
          onPressed: () => Navigator.of(context).pop(_Suite.ouvrirTableau),
          child: Text('Ouvrir le ${d.nomTableau.toLowerCase()}'),
        );
      case 'WRONG_STATUS':
        message = "Ce document n'est plus en attente de votre décision : il a avancé depuis votre lecture.";
        action = TextButton(
          onPressed: () => Navigator.of(context).pop(_Suite.relire),
          child: const Text('Revoir la fiche'),
        );
      case 'SIGNATURE_MANQUANTE':
        message = '${e.message} Elle est apposée sur le document à chaque approbation.';
      case 'PAIEMENT_INCOHERENT':
        if (d.actions.peutRejeter) {
          action = TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(d.actions.rejetAvecDestinataire ? 'Fermer, puis renvoyer' : 'Fermer, puis rejeter'),
          );
        }
      case 'UPLOAD_WINDOW_CLOSED' || 'NOT_EVENT_AUTHOR':
        break;
      default:
        if (e.statut == 409) message = '${e.message} Revenez à la fiche pour le relire.';
    }
    return EncartErreur(
      message: message,
      action: action == null
          ? null
          : Align(
              alignment: Alignment.centerLeft,
              child: TextButtonTheme(
                data: TextButtonThemeData(
                  style: TextButton.styleFrom(foregroundColor: p.danger, padding: EdgeInsets.zero),
                ),
                child: action,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final enCours = _etape == _Etape.decision || _etape == _Etape.pieces;
    final hauteurMax = MediaQuery.sizeOf(context).height * 0.92;

    return PopScope(
      canPop: !enCours,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: hauteurMax),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (e, a) => FadeTransition(
              opacity: a,
              child: SizeTransition(sizeFactor: a, child: e),
            ),
            child: _etape == _Etape.termine
                ? _Confirmation(
                    key: const ValueKey('ok'),
                    titre: _avertissement != null ? 'Décision enregistrée' : 'C’est fait',
                    message: _avertissement ?? _message ?? '',
                    avertissement: _avertissement != null,
                    statut: _statutFinal,
                  )
                : GestureDetector(
                    key: const ValueKey('saisie'),
                    behavior: HitTestBehavior.translucent,
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(Espace.l, 0, Espace.l, Espace.l),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(_titre, style: Typo.titre.copyWith(color: p.texte)),
                          const SizedBox(height: Espace.m),
                          _Recapitulatif(d: d),
                          const SizedBox(height: Espace.m),
                          ..._bandeaux(context),
                          if (_avecDestinataire) _choixDestinataire(context, enCours),
                          if (_avecTexte) ...[
                            Text(switch (mode) {
                              ModeDecision.approuver => 'Message pour l’étape suivante',
                              ModeDecision.rejeter => 'Motif du renvoi',
                              ModeDecision.info => 'Votre question',
                              _ => 'Votre réponse',
                            }, style: Typo.libelle.copyWith(color: p.texte)),
                            const SizedBox(height: Espace.xs + 2),
                            TextField(
                              controller: _texte,
                              enabled: !enCours,
                              minLines: 4,
                              maxLines: 8,
                              maxLength: 5000,
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: (_) {
                                if (_champEnErreur) setState(() => _champEnErreur = false);
                              },
                              decoration: InputDecoration(
                                enabledBorder: _champEnErreur
                                    ? OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(Rayon.m),
                                        borderSide: BorderSide(color: p.danger, width: 1.5),
                                      )
                                    : null,
                                hintText: switch (mode) {
                                  ModeDecision.rejeter => 'Expliquez ce qui doit être corrigé…',
                                  ModeDecision.approuver => 'Facultatif : un mot pour le prochain validateur…',
                                  _ => null,
                                },
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: Espace.l),
                          ],
                          if (_avecTexte) ...[
                            ChoixPieces(
                              pieces: _pieces,
                              onChange: (l) => setState(() => _pieces = l),
                              desactive: enCours,
                            ),
                            const SizedBox(height: Espace.l),
                          ],
                          if (_erreur != null) EncartErreur(message: _erreur!),
                          if (_erreurApi != null) _encartApi(_erreurApi!),
                          if (_etape == _Etape.pieces) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(value: _progression, minHeight: 6),
                            ),
                            const SizedBox(height: Espace.s),
                          ],
                          _boutonPrincipal(enCours),
                          const SizedBox(height: Espace.xs),
                          TextButton(
                            onPressed: enCours ? null : () => Navigator.of(context).pop(),
                            child: const Text('Annuler'),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _boutonPrincipal(bool enCours) {
    final libelle = _etape == _Etape.pieces
        ? 'Envoi des pièces jointes${_progression != null ? ' (${(_progression! * 100).round()} %)' : '…'}'
        : _titre;
    final onPressed = _bloqueSignature || enCours ? null : _valider;
    final chargement = _etape == _Etape.decision;
    return switch (mode) {
      ModeDecision.approuver ||
      ModeDecision.bc => BoutonApprobation(libelle: libelle, onPressed: onPressed, chargement: chargement),
      ModeDecision.rejeter => FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: context.dg.danger,
          foregroundColor: context.sombre ? const Color(0xFF3A0E0A) : Colors.white,
        ),
        icon: chargement
            ? Roue(couleur: context.sombre ? const Color(0xFF3A0E0A) : Colors.white)
            : const Icon(Icons.undo_rounded),
        label: Text(libelle),
      ),
      _ => FilledButton.icon(
        onPressed: onPressed,
        icon: chargement
            ? Roue(couleur: context.dg.surAction)
            : Icon(mode == ModeDecision.annulerBc ? Icons.cancel_outlined : Icons.send_rounded),
        label: Text(libelle),
      ),
    };
  }

  List<Widget> _bandeaux(BuildContext context) {
    final p = context.dg;
    final texte = Typo.secondaire.copyWith(color: p.texte);
    return [
      if (_bloqueSignature)
        Bandeau(
          ton: Ton.danger,
          icone: Icons.draw_outlined,
          titre: 'Signature manquante',
          child: Text(
            'Ajoutez votre signature dans votre profil DG Flow (web) avant de pouvoir approuver. '
            'Elle est apposée sur le document à chaque approbation.',
            style: texte,
          ),
        )
      else if (mode == ModeDecision.approuver)
        Bandeau(
          ton: Ton.info,
          icone: Icons.draw_outlined,
          titre: 'Votre signature sera apposée',
          child: Text(
            "La signature de votre profil DG Flow est ajoutée au document, et l'étape suivante est notifiée "
            '(application, web et email).',
            style: texte,
          ),
        )
      else if (mode == ModeDecision.bc)
        Bandeau(
          ton: Ton.alerte,
          icone: Icons.receipt_long_outlined,
          titre: 'Conversion en Bon de Commande',
          child: Text(
            'Le RC est marqué « Bon de Commande » ET approuvé par Service Gestion : votre signature est apposée '
            'et le circuit de validation se termine.',
            style: texte,
          ),
        )
      else if (mode == ModeDecision.annulerBc)
        Bandeau(
          ton: Ton.neutre,
          icone: Icons.receipt_long_outlined,
          titre: 'Annuler la conversion',
          child: Text("Le RC n'est plus un Bon de Commande et reste en attente de votre décision.", style: texte),
        ),
      if (mode == ModeDecision.reponse && d.demandeInfo != null)
        Bandeau(
          ton: Ton.info,
          icone: Icons.forum_outlined,
          titre: 'Question de ${d.demandeInfo!.par ?? '—'}',
          child: Text(d.demandeInfo!.message ?? '', style: Typo.corps.copyWith(color: p.texte)),
        ),
    ];
  }

  Widget _choixDestinataire(BuildContext context, bool enCours) {
    final p = context.dg;
    final propose = d.actions.destinatairePropose;
    return Padding(
      padding: const EdgeInsets.only(bottom: Espace.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            mode == ModeDecision.info ? 'À qui demander' : 'Renvoyer à',
            style: Typo.libelle.copyWith(color: p.texte),
          ),
          const SizedBox(height: Espace.xs + 2),
          Carte(
            padding: const EdgeInsets.symmetric(vertical: Espace.xs),
            child: _destinataires.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(Espace.l),
                    child: Text(
                      'Aucun destinataire disponible sur ce projet.',
                      style: Typo.secondaire.copyWith(color: p.texteSecondaire),
                    ),
                  )
                : RadioGroup<int>(
                    groupValue: _destinataire,
                    onChanged: (v) {
                      if (!enCours) setState(() => _destinataire = v);
                    },
                    child: Column(
                      children: [
                        for (final (i, x) in _destinataires.indexed)
                          Container(
                            decoration: BoxDecoration(
                              border: i < _destinataires.length - 1
                                  ? Border(bottom: BorderSide(color: p.bordure))
                                  : null,
                            ),
                            child: RadioListTile<int>(
                              value: x.id,
                              enabled: !enCours,
                              title: Text(x.nom, style: Typo.corps.copyWith(color: p.texte)),
                              subtitle: Text(
                                '${x.role}${x.id == propose ? ', dernier à avoir approuvé' : ''}',
                                style: Typo.secondaire.copyWith(color: p.texteSecondaire),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Recapitulatif extends StatelessWidget {
  const _Recapitulatif({required this.d});

  final Detail d;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    return Carte(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${d.estAvenant ? '${d.libelleType}, ' : ''}${d.reference}',
                  style: Typo.secondaire.copyWith(color: p.texteSecondaire),
                ),
                const SizedBox(height: 2),
                Text(d.intitule, style: Typo.sousTitre.copyWith(color: p.texte)),
                Text(
                  [d.projet.code, d.projet.nom].whereType<String>().join('  '),
                  style: Typo.secondaire.copyWith(color: p.texteSecondaire),
                ),
              ],
            ),
          ),
          if (d.montants.montantRetenu != null) ...[
            const SizedBox(width: Espace.m),
            Text(
              Format.euros(d.montants.montantRetenu, arrondi: true),
              style: Typo.montant.copyWith(fontSize: 19, color: p.texte),
            ),
          ],
        ],
      ),
    );
  }
}

/// Confirmation claire après la décision.
class _Confirmation extends StatelessWidget {
  const _Confirmation({
    required this.titre,
    required this.message,
    required this.avertissement,
    this.statut,
    super.key,
  });

  final String titre;
  final String message;
  final bool avertissement;

  /// Statut après la décision : le fil montre où va le document.
  final String? statut;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final couleur = avertissement ? p.alerte : p.succes;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Espace.xl, Espace.s, Espace.xl, Espace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 420),
            curve: Curves.elasticOut,
            builder: (context, v, enfant) => Transform.scale(scale: v, child: enfant),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(color: avertissement ? p.alerteFond : p.succesFond, shape: BoxShape.circle),
              child: Icon(avertissement ? Icons.priority_high_rounded : Icons.check_rounded, size: 42, color: couleur),
            ),
          ),
          const SizedBox(height: Espace.l),
          Semantics(
            liveRegion: true,
            child: Text(titre, style: Typo.titre.copyWith(color: p.texte)),
          ),
          const SizedBox(height: Espace.s),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Typo.corps.copyWith(color: p.texteSecondaire),
          ),
          if (statut != null) ...[
            const SizedBox(height: Espace.l + 4),
            FilParcours(statut: statut!, anime: true),
            const SizedBox(height: Espace.s),
            Text(positionParcours(statut!).phrase, style: Typo.libelle.copyWith(color: p.texteSecondaire)),
          ],
          const SizedBox(height: Espace.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Retour à la fiche')),
          ),
        ],
      ),
    );
  }
}
