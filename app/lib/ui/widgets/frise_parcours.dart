import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/parcours.dart';
import '../../core/utils/format.dart';
import '../theme.dart';
import 'composants.dart';
import 'liste_pieces.dart';

/// Présentation d'un état d'étape, comme la frise « Suivi du RC » du web
/// (`RcWorkflowDialog.tsx`) : cercle teinté, icône, pastille d'état.
({Teinte teinte, IconData icone, String libelle}) _style(Palette p, EtatEtape e) => switch (e) {
  EtatEtape.completed => (teinte: p.vert, icone: LucideIcons.checkCircle, libelle: 'Terminé'),
  EtatEtape.current => (teinte: p.orange, icone: LucideIcons.clock, libelle: 'En cours'),
  EtatEtape.rejected => (teinte: p.rouge, icone: LucideIcons.xCircle, libelle: 'Rejeté'),
  EtatEtape.info => (teinte: p.ambre, icone: LucideIcons.messageCircleQuestion, libelle: 'Information'),
  EtatEtape.note => (teinte: p.gris, icone: LucideIcons.stickyNote, libelle: 'Note'),
};

/// Frise du parcours : création → étapes de validation → étape en attente.
class FriseParcours extends StatelessWidget {
  const FriseParcours({required this.rcId, required this.etapes, super.key});

  final int rcId;
  final List<EtapeParcours> etapes;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < etapes.length; i++)
          _Etape(etape: etapes[i], style: _style(p, etapes[i].etat), derniere: i == etapes.length - 1, rcId: rcId),
      ],
    );
  }
}

class _Etape extends StatelessWidget {
  const _Etape({required this.etape, required this.style, required this.derniere, required this.rcId});

  final EtapeParcours etape;
  final ({Teinte teinte, IconData icone, String libelle}) style;
  final bool derniere;
  final int rcId;

  static const double _cercle = 40;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final e = etape;
    final t = style.teinte;
    // Message : vert, ambre pour une demande d'information, gris pour une note
    // ou un message automatique.
    final teinteMessage = e.automatique || e.etat == EtatEtape.note
        ? p.gris
        : e.etat == EtatEtape.info
        ? p.ambre
        : p.vert;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _cercle,
            child: Column(
              children: [
                CercleIcone(teinte: t, icone: style.icone, taille: _cercle, tailleIcone: 20),
                if (!derniere) Expanded(child: Container(width: 2, color: p.bordureForte)),
              ],
            ),
          ),
          const SizedBox(width: Espace.m),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: derniere ? 0 : Espace.l, top: 2),
              child: Semantics(
                container: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text(e.etape, style: Typo.corpsFort.copyWith(color: p.texte, height: 1.35)),
                          ),
                        ),
                        const SizedBox(width: Espace.s),
                        Pastille(libelle: style.libelle, teinte: t, petite: true),
                      ],
                    ),
                    if (e.par != null) _Ligne(icone: LucideIcons.user, texte: e.par!),
                    if (e.le != null) _Ligne(icone: LucideIcons.calendar, texte: Format.dateHeure(e.le)),
                    if (e.vers != null && e.etat != EtatEtape.completed)
                      _Ligne(icone: LucideIcons.arrowRight, texte: 'Adressé à ${e.vers}'),
                    if (e.motif != null && e.motif!.isNotEmpty)
                      _Bloc(
                        teinte: p.rouge,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Raison du rejet : ',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              TextSpan(text: e.motif),
                            ],
                          ),
                          style: Typo.secondaire.copyWith(color: p.rouge.texte),
                        ),
                      ),
                    if (e.message != null && e.message!.isNotEmpty)
                      _Bloc(
                        teinte: teinteMessage,
                        icone: e.automatique ? null : LucideIcons.messageSquare,
                        child: Text(
                          e.automatique ? e.message! : '« ${e.message} »',
                          style: Typo.secondaire.copyWith(color: teinteMessage.texte),
                        ),
                      ),
                    ListePieces(rcId: rcId, pieces: e.pieces),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne utilisateur / date : `text-sm text-gray-600`, icône `w-4 h-4`.
class _Ligne extends StatelessWidget {
  const _Ligne({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icone, size: 15, color: p.texteSecondaire),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(texte, style: Typo.secondaire.copyWith(color: p.texteSecondaire)),
          ),
        ],
      ),
    );
  }
}

/// Bloc teinté d'une étape : `p-3 bg-*-50 border border-*-200 rounded-lg`.
class _Bloc extends StatelessWidget {
  const _Bloc({required this.teinte, required this.child, this.icone});

  final Teinte teinte;
  final Widget child;
  final IconData? icone;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: Espace.s),
    padding: const EdgeInsets.all(Espace.m),
    decoration: BoxDecoration(
      color: teinte.fondDoux,
      border: Border.all(color: teinte.bordDoux),
      borderRadius: BorderRadius.circular(Rayon.m),
    ),
    child: icone == null
        ? child
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icone, size: 15, color: teinte.vif),
              ),
              const SizedBox(width: Espace.s),
              Expanded(child: child),
            ],
          ),
  );
}
