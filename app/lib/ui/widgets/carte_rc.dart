import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/models.dart';
import '../../core/utils/format.dart';
import '../etat_rc.dart';
import '../theme.dart';
import 'composants.dart';
import 'fil_parcours.dart';

/// Habillage de la carte selon l'état du document (voir [habillageEtatRc]).
({Color? lisere, Color fondEnTete, List<Color> degrade}) _habillage(BuildContext context, ElementListe rc) {
  final h = habillageEtatRc(
    context.dg,
    statut: rc.statut,
    avenant: rc.type == TypeDocument.avenant,
    decideur: rc.aTraiter,
    infoPourMoi: rc.infoPourMoi,
  );
  return (lisere: h.lisere, fondEnTete: h.teinte.fondDoux, degrade: h.degrade);
}

/// Carte d'un RC / avenant dans les listes « À traiter » et « Suivi ».
class CarteRc extends StatelessWidget {
  const CarteRc({required this.rc, required this.onTap, super.key});

  final ElementListe rc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final etat = phrasePosition(context, statut: rc.statut, decideur: rc.aTraiter, infoPourMoi: rc.infoPourMoi);
    final avenant = rc.type == TypeDocument.avenant;
    final type = avenant ? 'Avenant ${rc.numeroAvenant ?? ''}'.trim() : 'RC';
    final h = _habillage(context, rc);
    final retrait = h.lisere == null ? 0.0 : 4.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: Espace.m),
      child: Semantics(
        button: true,
        label: '$type ${rc.reference}, ${rc.intitule}, ${etat.texte}',
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Rayon.l),
            boxShadow: context.sombre ? null : OmbreWeb.sm,
          ),
          child: Material(
            color: p.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Rayon.l),
              side: BorderSide(color: p.bordure),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // En-tête teinté : `!py-3 px-4 border-b border-gray-100 min-h-[64px]`.
                      Container(
                        constraints: const BoxConstraints(minHeight: 64),
                        padding: EdgeInsets.fromLTRB(Espace.l + retrait, Espace.m, Espace.l, Espace.m),
                        decoration: BoxDecoration(
                          color: h.fondEnTete,
                          border: Border(bottom: BorderSide(color: p.bordure)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Tuile(degrade: h.degrade, avenant: avenant),
                            const SizedBox(width: Espace.m),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      TagType(avenant: avenant, numero: rc.numeroAvenant),
                                      const SizedBox(width: Espace.s),
                                      Expanded(
                                        child: Text(
                                          rc.reference,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Typo.code.copyWith(color: p.action),
                                        ),
                                      ),
                                      if (rc.dernierEvenement != null) ...[
                                        const SizedBox(width: Espace.s),
                                        Text(
                                          Format.relatif(rc.dernierEvenement!.le),
                                          style: Typo.petit.copyWith(color: p.texteTertiaire),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    rc.intitule,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Typo.sousTitre.copyWith(color: p.titre),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(Espace.l + retrait, Espace.m, Espace.l, Espace.l),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: rc.projet.code ?? '—',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: p.texte),
                                  ),
                                  if (rc.projet.nom != null) TextSpan(text: '  ${rc.projet.nom}'),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Typo.secondaire.copyWith(color: p.texteSecondaire),
                            ),
                            if (rc.entreprise != null) ...[
                              const SizedBox(height: Espace.m),
                              // Bloc `bg-gray-50 rounded-lg p-3 border border-gray-100`.
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: Espace.m, vertical: 10),
                                decoration: BoxDecoration(
                                  color: p.gris.fondDoux,
                                  border: Border.all(color: p.gris.fond),
                                  borderRadius: BorderRadius.circular(Rayon.m),
                                ),
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.building2, size: 16, color: p.action),
                                    const SizedBox(width: Espace.s),
                                    Expanded(
                                      child: Text(
                                        rc.entreprise!.nom ?? 'Entreprise retenue',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Typo.secondaire.copyWith(
                                          color: p.texteSecondaire,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: Espace.m),
                                    Text(
                                      Format.euros(rc.entreprise!.montant, arrondi: true),
                                      style: Typo.montant.copyWith(color: p.texte, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: Espace.m),
                            FilParcours(statut: rc.statut),
                            const SizedBox(height: Espace.m),
                            Row(
                              children: [
                                if (etat.icone != null) ...[
                                  Icon(etat.icone, size: 16, color: etat.couleur),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Text(
                                    etat.texte,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Typo.secondaire.copyWith(
                                      color: etat.couleur,
                                      fontWeight: etat.fort ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: Espace.s),
                                Pastille(libelle: rc.libelle, ton: rc.ton, petite: true),
                                if (rc.estBc) ...[
                                  const SizedBox(width: Espace.xs),
                                  Pastille(
                                    libelle: 'BC',
                                    teinte: p.bleu,
                                    icone: LucideIcons.shoppingCart,
                                    petite: true,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (h.lisere != null)
                    Positioned(left: 0, top: 0, bottom: 0, width: 4, child: ColoredBox(color: h.lisere!)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tuile d'icône `w-8 h-8 rounded-lg` en dégradé, FileText blanc (Layers pour un avenant).
class _Tuile extends StatelessWidget {
  const _Tuile({required this.degrade, required this.avenant});

  final List<Color> degrade;
  final bool avenant;

  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: degrade),
      borderRadius: BorderRadius.circular(Rayon.m),
    ),
    child: Icon(avenant ? LucideIcons.layers : LucideIcons.fileText, size: 16, color: Colors.white),
  );
}
