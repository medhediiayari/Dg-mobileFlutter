import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/utils/parcours.dart';
import '../theme.dart';

/// État d'une étape du fil.
enum _Etat { fait, courant, renvoi, brouillon, rejete, aVenir }

/// États des cinq étapes RP · DP · DEX · DE · SG d'après la position du document.
List<_Etat> _etats(PositionParcours pos) {
  final n = etapesCircuit.length;
  return [
    for (var i = 0; i < n; i++)
      switch (pos.mode) {
        ModeParcours.termine => _Etat.fait,
        ModeParcours.brouillon => i == 0 ? _Etat.brouillon : _Etat.aVenir,
        ModeParcours.attente =>
          i < pos.index
              ? _Etat.fait
              : i == pos.index
              ? _Etat.courant
              : _Etat.aVenir,
        ModeParcours.renvoi =>
          i < pos.index
              ? _Etat.fait
              : i == pos.index
              ? _Etat.renvoi
              : i == pos.origine
              ? _Etat.rejete
              : _Etat.aVenir,
      },
  ];
}

/// Le fil du parcours, comme la frise horizontale du web (`RCProgressionBoard`) :
/// cinq pastilles RP · DP · DEX · DE · SG — franchie `bg-emerald-500` + coche,
/// en cours `bg-blue-500` + horloge et anneau `ring-blue-200` (orange si le
/// document a été renvoyé, gris pour un brouillon), étape qui a rejeté
/// `bg-red-500` + croix, à venir `bg-slate-200` + numéro. Liaisons de 2 px :
/// émeraude après une étape franchie, rouge vers un rejet, gris sinon ; sigles
/// sous les pastilles.
///
/// [anime] : à la première apparition, les étapes s'allument une à une jusqu'à
/// l'étape en cours (désactivé si l'utilisateur réduit les animations).
class FilParcours extends StatefulWidget {
  const FilParcours({required this.statut, this.grand = false, this.anime = false, super.key});

  final String statut;
  final bool grand;
  final bool anime;

  @override
  State<FilParcours> createState() => _FilParcoursState();
}

class _FilParcoursState extends State<FilParcours> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: widget.anime ? 0 : 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.anime && _anim.value == 0) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _anim.value = 1;
      } else {
        _anim.forward();
      }
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final pos = positionParcours(widget.statut);
    final etats = _etats(pos);
    final echelle = math.min(MediaQuery.textScalerOf(context).scale(1), 1.35);
    final diametre = (widget.grand ? 30.0 : 24.0) * echelle;
    final tailleSigle = (widget.grand ? 11.0 : 10.0) * echelle;

    return Semantics(
      label: 'Parcours : ${pos.phrase}',
      container: true,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(_anim.value);
          final n = etapesCircuit.length;
          // Avancement de l'allumage de l'étape i (0 → 1).
          double allume(int i) => ((t * (n + 0.5)) - i).clamp(0.0, 1.0);
          return LayoutBuilder(
            builder: (context, c) {
              final largeur = c.maxWidth / n;
              return SizedBox(
                height: diametre + 4 + tailleSigle * 1.3,
                child: Stack(
                  children: [
                    for (var i = 0; i < n - 1; i++)
                      Positioned(
                        left: (i + 0.5) * largeur + diametre / 2 + 4,
                        width: math.max(0, largeur - diametre - 8),
                        top: diametre / 2 - 1,
                        height: 2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              p.gris.bordDoux,
                              _couleurLiaison(p, etats[i], etats[i + 1]),
                              allume(i + 1),
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        for (var i = 0; i < n; i++)
                          SizedBox(
                            width: largeur,
                            child: _Pastille(
                              index: i,
                              etat: etats[i],
                              allume: allume(i),
                              diametre: diametre,
                              tailleSigle: tailleSigle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Liaison entre deux étapes : `emerald-400` après une étape franchie,
/// `red-400` vers l'étape qui a rejeté, `slate-200` sinon.
Color _couleurLiaison(Palette p, _Etat de, _Etat vers) {
  if (vers == _Etat.rejete) return Tw.red400;
  if (de == _Etat.fait) return Tw.emerald400;
  return p.gris.bordDoux;
}

class _Pastille extends StatelessWidget {
  const _Pastille({
    required this.index,
    required this.etat,
    required this.allume,
    required this.diametre,
    required this.tailleSigle,
  });

  final int index;
  final _Etat etat;
  final double allume;
  final double diametre;
  final double tailleSigle;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final (fond, encre, anneau) = switch (etat) {
      _Etat.fait => (p.emeraude.plein, p.emeraude.vif, null),
      _Etat.courant => (p.bleu.plein, p.bleu.vif, p.bleu.bordDoux),
      _Etat.renvoi => (p.orange.plein, p.orange.vif, p.orange.bordDoux),
      _Etat.brouillon => (p.gris.plein, p.gris.vif, p.gris.bordDoux),
      _Etat.rejete => (p.rouge.plein, p.rouge.vif, null),
      _Etat.aVenir => (p.gris.bordDoux, p.texteDiscret, null),
    };
    final icone = switch (etat) {
      _Etat.fait => LucideIcons.check,
      _Etat.courant || _Etat.brouillon => LucideIcons.clock,
      _Etat.renvoi => LucideIcons.undo2,
      _Etat.rejete => LucideIcons.x,
      _Etat.aVenir => null,
    };
    final enCours = etat == _Etat.courant || etat == _Etat.renvoi || etat == _Etat.brouillon;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: diametre,
          height: diametre,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color.lerp(p.gris.bordDoux, fond, allume),
            shape: BoxShape.circle,
            boxShadow: [
              if (anneau != null && allume > 0) BoxShadow(color: anneau.withValues(alpha: allume), spreadRadius: 2.5),
              if (etat == _Etat.fait && !context.sombre && allume > 0)
                BoxShadow(
                  color: p.emeraude.bordDoux.withValues(alpha: allume),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: icone == null
              ? Text(
                  '${index + 1}',
                  style: Typo.petit.copyWith(
                    fontSize: diametre * 0.42,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: p.texteDiscret,
                  ),
                )
              : Opacity(
                  opacity: allume,
                  child: Icon(icone, size: diametre * 0.55, color: Colors.white),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          etapesCircuit[index].sigle,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: Typo.sigle.copyWith(
            fontSize: tailleSigle,
            fontWeight: enCours ? FontWeight.w700 : FontWeight.w600,
            height: 1.2,
            color: Color.lerp(p.texteDiscret, encre, allume),
          ),
        ),
      ],
    );
  }
}

/// Phrase de position vue par l'utilisateur, et sa couleur.
({String texte, IconData? icone, Color couleur, bool fort}) phrasePosition(
  BuildContext context, {
  required String statut,
  required bool decideur,
  required bool infoPourMoi,
}) {
  final p = context.dg;
  final pos = positionParcours(statut);
  if (infoPourMoi) {
    return (
      texte: 'Une information vous est demandée',
      icone: LucideIcons.messageCircleQuestion,
      couleur: p.ambre.vif,
      fort: true,
    );
  }
  if (decideur) {
    if (pos.mode == ModeParcours.brouillon) {
      return (
        texte: 'Brouillon à finaliser sur DG Flow web',
        icone: LucideIcons.filePen,
        couleur: p.texteSecondaire,
        fort: true,
      );
    }
    if (pos.mode == ModeParcours.renvoi && pos.origine != null) {
      return (
        texte:
            'Renvoyé par le ${etapesCircuit[pos.origine!].sigle}, ${pos.index == 0 ? 'à corriger sur DG Flow web' : 'à vous de reprendre'}',
        icone: LucideIcons.undo2,
        couleur: p.orange.vif,
        fort: true,
      );
    }
    return (texte: 'À vous de décider', icone: LucideIcons.circleDot, couleur: p.action, fort: true);
  }
  return (
    texte: pos.phrase,
    icone: pos.mode == ModeParcours.termine ? LucideIcons.checkCircle : null,
    couleur: pos.mode == ModeParcours.termine ? p.emeraude.vif : p.texteSecondaire,
    fort: false,
  );
}
