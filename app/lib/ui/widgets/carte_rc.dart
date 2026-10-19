import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/utils/format.dart';
import '../../core/utils/parcours.dart';
import '../theme.dart';
import 'composants.dart';
import 'fil_parcours.dart';

/// Carte d'un RC / avenant dans les listes « À traiter » et « Suivi ».
class CarteRc extends StatelessWidget {
  const CarteRc({required this.rc, required this.onTap, super.key});

  final ElementListe rc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final etat = phrasePosition(context, statut: rc.statut, decideur: rc.aTraiter, infoPourMoi: rc.infoPourMoi);
    final pos = positionParcours(rc.statut);
    final accent = rc.infoPourMoi
        ? p.action
        : rc.aTraiter
        ? (pos.mode == ModeParcours.renvoi ? p.alerte : p.action)
        : null;
    final type = rc.type == TypeDocument.avenant ? 'Avenant ${rc.numeroAvenant ?? ''}'.trim() : 'RC';

    return Padding(
      padding: const EdgeInsets.only(bottom: Espace.m),
      child: Semantics(
        button: true,
        label: '$type ${rc.reference}, ${rc.intitule}, ${etat.texte}',
        excludeSemantics: true,
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
                if (accent != null) Positioned(left: 0, top: 0, bottom: 0, width: 4, child: ColoredBox(color: accent)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Espace.l + 2, Espace.l, Espace.l, Espace.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TagType(avenant: rc.type == TypeDocument.avenant, numero: rc.numeroAvenant),
                          const SizedBox(width: Espace.s),
                          Expanded(
                            child: Text(
                              rc.reference,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Typo.sousTitre.copyWith(
                                fontSize: 15,
                                color: p.texteSecondaire,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (rc.dernierEvenement != null)
                            Text(
                              Format.relatif(rc.dernierEvenement!.le),
                              style: Typo.petit.copyWith(color: p.texteTertiaire),
                            ),
                        ],
                      ),
                      const SizedBox(height: Espace.s),
                      Text(
                        rc.intitule,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Typo.sousTitre.copyWith(color: p.texte),
                      ),
                      const SizedBox(height: 2),
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
                        Container(
                          padding: const EdgeInsets.only(top: Espace.m),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: p.bordure)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  rc.entreprise!.nom ?? 'Entreprise retenue',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Typo.secondaire.copyWith(color: p.texteSecondaire),
                                ),
                              ),
                              const SizedBox(width: Espace.m),
                              Text(
                                Format.euros(rc.entreprise!.montant, arrondi: true),
                                style: Typo.montant.copyWith(fontSize: 19, color: p.texte),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: Espace.m),
                      FilParcours(statut: rc.statut),
                      const SizedBox(height: Espace.s + 2),
                      Row(
                        children: [
                          if (etat.icone != null) ...[
                            Icon(
                              etat.icone,
                              size: etat.icone == Icons.radio_button_checked_rounded ? 12 : 16,
                              color: etat.couleur,
                            ),
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
                            const Pastille(libelle: 'BC', ton: Ton.alerte, petite: true),
                          ],
                        ],
                      ),
                      if (rc.consultationRequise != null && !rc.infoPourMoi) ...[
                        const SizedBox(height: Espace.s),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: Espace.s, vertical: 6),
                          decoration: BoxDecoration(color: p.neutreFond, borderRadius: BorderRadius.circular(Rayon.s)),
                          child: Row(
                            children: [
                              Icon(Icons.visibility_outlined, size: 15, color: p.texteSecondaire),
                              const SizedBox(width: Espace.s),
                              Expanded(
                                child: Text(
                                  rc.consultationRequise!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Typo.petit.copyWith(color: p.texteSecondaire),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
