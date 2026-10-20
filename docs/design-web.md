# Design de l'app Flutter = design du web DG Flow

L'application reprend **l'identité graphique de DG Flow web** (`C:\Users\user\Desktop\dgflow`) :
mêmes couleurs, mêmes polices, mêmes icônes, mêmes codes visuels pour les statuts, le parcours
et les décisions. Ce document liste chaque référence relevée dans le web et son équivalent Flutter.

| Côté web | Côté Flutter |
|---|---|
| `app/globals.css` (jetons shadcn/ui, couleurs DG Group, polices) | `app/lib/ui/jetons_web.dart` (valeurs exactes) |
| Classes Tailwind des écrans RC | `app/lib/ui/theme.dart` (`Palette`, `Teinte`, `Typo`, thème Material) |
| Composants shadcn/ui + motifs RC | `app/lib/ui/widgets/composants.dart` |
| `lucide-react` 0.454 | `lucide_icons_flutter` (`LucideIcons.*`), mêmes noms |
| IBM Plex Sans Variable / IBM Plex Mono (`@fontsource`) | `assets/fonts/IBMPlexSans-*.ttf`, `IBMPlexMono-*.ttf` (fichiers officiels IBM) |

> Règle : **aucune couleur en dur dans les écrans**. Les écrans utilisent `context.dg` (`Palette`) ;
> la palette dérive de `jetons_web.dart`. Le web est en **Tailwind v4** : ses couleurs sont en oklch,
> `jetons_web.dart` en contient la conversion sRGB exacte (ex. `red-600` = `#E7000B`,
> `green-600` = `#00A63E`, `blue-600` = `#155DFC`).

---

## 1. Couleurs de marque (`globals.css` et valeurs littérales)

| Jeton | Hex | Usage web | Flutter |
|---|---|---|---|
| Marine | `#172D4C` | `--primary`, sidebar, titres (`text-[#172D4C]`) | `Marque.marine`, `p.marine`, `p.titre` |
| Marine bandeau | `#162C4B` | bandeau des indicateurs | `Marque.marineBandeau`, `p.marineProfond` |
| Fin de dégradé | `#1E3D6B` | en-têtes `from-[#172D4C] to-[#1e3d6b]` | `Marque.marineDegrade`, `DegradeEnTete` |
| Bleu DG | `#0061A7` | `--accent`, `--ring`, nav active, bouton principal, liens | `Marque.bleu`, `p.action` |
| Bleu foncé | `#004D85` | survol du bouton principal | `p.actionFonce` |
| Bleu moyen | `#4F8FCC` | `--secondary` ; `--primary` sombre | `Marque.bleuMoyen` |
| Bleu pâle | `#8BB1E0` | texte inactif de la sidebar | `p.surMarineDoux` |
| Fond de page | `#F6F7F8` | pages RC `bg-[#f6f7f8]` | `p.fond` |
| Cyan « à traiter » | `#0E7490` | `PendingWorkBadge` | `Marque.cyanATraiter` |

**Jetons shadcn** (`:root` / `.dark`, convertis d'oklch) : foreground `#0B0B0B` / `#FAFAFA`,
muted `#F5F5F5` / `#262626`, muted-foreground `#555555` / `#A1A1A1`, border `#DEDEDE` / `#262626`,
destructive `#E7000B`, sidebar sombre `#171717`, fond sombre `#0A0A0A` → `Shadcn.*`.

### Palette Flutter (`context.dg`)

| Jeton | Clair | Sombre | Classe web |
|---|---|---|---|
| `fond` | `#F6F7F8` | `#0A0A0A` | `bg-[#f6f7f8]` / `.dark --background` |
| `surface` | blanc | `#171717` | `bg-white` (cartes, feuilles, dialogues) |
| `surfaceRelief` | gray-100 | `#262626` | `bg-gray-100` (onglets, recherche) |
| `bordure` / `bordureForte` | gray-200 / gray-300 | `#262626` / neutral-700 | `border-gray-200/300` |
| `texte` | gray-900 | `#FAFAFA` | `text-gray-900` |
| `titre` | `#172D4C` | `#FAFAFA` | `text-[#172D4C]` |
| `texteSecondaire` / `texteTertiaire` / `texteDiscret` | gray-600 / 500 / 400 | `#A1A1A1` / neutral-500 / 600 | |
| `action` / `surAction` | `#0061A7` / blanc | `#4F8FCC` / `#0A0A0A` | bouton principal, liens |
| `accentClair` | blue-50 | blue-950 | `bg-blue-50`, `bg-[#0061A7]/5` |

### Familles de couleur (`Teinte`)

Chaque famille Tailwind employée par les écrans RC est une `Teinte` :

| Champ | Nuance | Usage web |
|---|---|---|
| `fondDoux` | 50 | bandeaux `bg-*-50` |
| `fond` | 100 | pastilles, cercles d'icône `bg-*-100` |
| `bordDoux` | 200 | bord des bandeaux `border-*-200` |
| `bord` | 300 | bord des pastilles, boutons contour `border-2 border-*-300` |
| `plein` | 500 | liseré `border-l-*-500`, pastilles pleines |
| `vif` | 600 | icônes, texte des boutons contour, boutons pleins |
| `fonce` | 700 | fin de dégradé |
| `texte` | 800 | texte des pastilles et bandeaux |

Familles : `gris`, `bleu`, `vert`, `emeraude`, `rouge`, `orange`, `ambre`, `teal`, `indigo`,
`violet` (Tailwind *purple*). En sombre, idiome Tailwind `dark:` (fond 900/950, texte 200, icône 400).

**Sens des couleurs dans les écrans RC du web**

| Sens | Famille |
|---|---|
| En attente / à décider (cartes DP, DEX, DE) | `bleu` (+ liseré `#0061A7`) |
| Approuvé | `vert` ; validé par le SG : `emeraude` |
| Rejeté | `rouge` |
| Renvoyé vers un autre rôle (`*_to_*`) | `orange` |
| Demande / réponse d'information, correction requise | `ambre` |
| **Avenant** | `teal` (partout) |
| Bon de commande | `bleu` + texte `#0061A7` + ShoppingCart |
| Consulter / Tableau / Suivre / Fichiers | `bleu` / `indigo` / `violet` / `orange` |

---

## 2. Statuts

L'API mobile renvoie un **ton** par statut (`dgflow/lib/mobile/rc/statuts.ts`) ; `Palette.ton()`
lui donne la famille du web (`RC_STATUS_CONFIG`, `lib/rc-status.ts`) :

| Ton API | Statuts | Famille | Pastille |
|---|---|---|---|
| `neutre` | `draft` | `gris` | `bg-gray-100 text-gray-800` + FileText |
| `info` | `approved_by_*` (sauf SG) — en cours de circuit | `bleu` | `bg-blue-100 text-blue-800 border-blue-300` + Clock |
| `succes` | `approved_by_service_gestion` | `emeraude` | `bg-emerald-100 text-emerald-800` + CheckCircle |
| `alerte` | `rejected_*_to_*` (renvoi SG / DE) | `orange` | `bg-orange-100 text-orange-800` + XCircle |
| `danger` | autres `rejected_*` | `rouge` | `bg-red-100 text-red-800 border-red-300` + XCircle |

Pastille (`Pastille`) : `rounded-md border px-2 py-0.5 text-xs font-semibold`, icône 12 px.
Compteurs d'en-tête de liste : `Badge variant=outline` `bg-orange-50 text-orange-700` (en attente),
`bg-green-50 text-green-700` (approuvés), `bg-red-50 text-red-700` (rejetés).

## 3. Parcours (frise, `RcWorkflowDialog.tsx`)

| État | Cercle | Icône | Pastille |
|---|---|---|---|
| terminé | `bg-green-100` | CheckCircle `text-green-600` | « Terminé » vert |
| en cours | `bg-orange-100` | Clock `text-orange-600` | « En cours » orange |
| rejeté | `bg-red-100` | XCircle `text-red-600` | « Rejeté » rouge |
| information | `bg-amber-100` | MessageCircleQuestion `text-amber-600` | « Information » ambre |
| note | `bg-slate-100` | StickyNote `text-slate-600` | « Note » gris |
| en attente | `bg-gray-100` | Clock `text-gray-400` | « En attente » gris |

Cercle `w-12 h-12 rounded-full`, trait vertical `w-0.5 bg-gray-300`, titre `font-semibold
text-gray-900`, lignes utilisateur / date `text-sm text-gray-600` (icônes User, Calendar).
Motif de rejet : `p-3 bg-red-50 border border-red-200 rounded-lg text-red-800`, « Raison du rejet : »
en gras. Message : vert (`green-50/200/800`), ambre pour une information, gris pour une note.

**Fil horizontal** (cartes, `RCProgressionBoard.tsx`) : cercles `w-7 h-7` — terminé
`bg-emerald-500` + Check blanc, en cours `bg-blue-500` + Clock + anneau `ring-blue-200`, rejeté
`bg-red-500` + XCircle, à venir `bg-slate-200 text-slate-400` + numéro ; liaisons `h-0.5`
emerald-400 (franchie), red-400 (vers un rejet), slate-200 ; sigles 9–10 px.

## 4. Décisions

| Action | Bouton (carte) | Confirmation (dialogue) | Icône |
|---|---|---|---|
| Approuver et signer | dégradé `green-600 → green-700`, blanc, `shadow-md` (`BoutonApprobation`) | idem, « Confirmer l'approbation » ; cercle `bg-green-100` | CheckCircle |
| Rejeter (DP, DEX) | contour `border-2 red-300 text-red-600` (`BoutonRefus`) | `bg-red-600` « Confirmer le rejet » ; avertissement ambre | XCircle |
| Renvoyer (DE) | contour rouge | `bg-red-600` « Renvoyer » ; cercle `bg-red-100` + AlertTriangle | XCircle |
| Renvoyer (SG) | contour rouge | **orange** `bg-orange-600` | XCircle |
| Demande d'information | contour `amber-300 / amber-600` | `bg-amber-600` « Envoyer la demande » | MessageCircleQuestion |
| Répondre | `bg-amber-600` « Répondre à la demande d'information » | `bg-amber-600` « Envoyer la réponse » + Send | MessageCircleQuestion |
| Bon de commande (SG) | `bg-[#0061A7]` | « Convertir et approuver » `#0061A7` ; annulation `destructive` | ShoppingCart |
| Consulter le RC | contour `blue-300 / blue-600` | — | Eye |
| Tableau comparatif / explicatif | contour `indigo-300 / indigo-600` | — | Eye |
| Avenants | contour `teal` | — | Layers |
| Suivre | contour `purple` | — | ArrowRight |
| Fichiers | contour `orange` | — | Folder |
| Annuler | contour neutre | — | — |

Approuver / Rejeter restent grisés (`opacity-50`) tant que le document n'a pas été consulté.
Puces de rôle (choix du destinataire, `rounded-full text-[11px] font-semibold`) : Exploitation
`ambre`, Études `emeraude`, Directeur projet `indigo`, Responsable `bleu`.

## 5. Cartes, listes, en-têtes

- **Carte RC** : shadcn Card `rounded-xl border shadow-sm bg-white` + **liseré `border-l-4`** :
  rejeté / renvoyé `red-500`, approuvé `emerald-500`, en attente `#0061A7`, correction requise
  `amber-500`, avenant en attente `teal-500`. En-tête teinté (`from-*-50`), tuile d'icône
  `w-8 h-8 rounded-lg` en dégradé (`from-[#0061A7] to-blue-600` ; avenant `teal-600 → teal-700`)
  avec FileText blanc (Layers pour un avenant), titre `text-lg font-bold text-[#172D4C]`.
  Bloc date `bg-gray-50 rounded-lg border-gray-100`, Calendar `text-[#0061A7]`.
- **En-tête de page** : `bg-gradient-to-r from-[#172D4C] to-[#1e3d6b]` (`DegradeEnTete`), titre
  `text-xl font-bold text-white tracking-tight`, sous-titre `text-sm text-white/60`, retour
  `w-10 h-10 rounded-xl bg-white/10`.
- **Bandeau d'indicateurs** : `bg-[#162c4b]`, tuiles `rounded-xl border-white/20 bg-white/10`,
  valeur `text-2xl font-bold text-white`, libellé `text-sm font-semibold text-white/90`.
- **Titre de section** : `font-bold text-[#172D4C]` + icône `text-[#0061A7]` (`Section(icone:)`).
- **État vide** : `py-12 bg-gray-50 rounded-xl border-dashed border-gray-300`, cercle
  `w-16 h-16 bg-gray-100`, icône `text-gray-400` (`EtatVide`).
- **Onglets** : `p-1 rounded-lg bg-gray-100 border-gray-200`, actif `bg-white text-[#0061A7]
  shadow-sm`, compteur `rounded-full bg-[#0061A7] text-white` / `bg-gray-300 text-gray-600`
  (`Segment`, `Compteur`).
- **Montants** : jamais en chasse fixe, `font-semibold tabular-nums`, `1 234,56 €`.
  `font-mono` seulement pour les **codes** (`text-sm font-bold text-[#0061A7] tracking-wide`,
  `Typo.code`).

## 6. Navigation (sidebar du web → barre d'onglets)

Sidebar `bg-[#172D4C]` : élément actif `bg-[#0061A7] text-white`, inactif `text-[#8BB1E0]`,
icônes `w-5 h-5`, libellés 13 px, compteur de non-lues `bg-red-500 rounded-full`. La barre
d'onglets de l'app reprend exactement ces couleurs (`navigationBarTheme`).
Logo sur fond marine : `dgflow-sidebar.png` (« DG » blanc) → `assets/images/logo-dgflow-dark.png`.

**Alertes** (`NotificationBell.tsx`) : panneau `rounded-xl border-gray-200 shadow-2xl`, en-tête de
groupe `text-[11px] font-semibold uppercase tracking-wide text-gray-500 bg-gray-50` (`Typo.surTitre`),
non lue `bg-blue-50/50` + barre gauche `w-[3px] bg-blue-500`, avatar `size-9` + puce de type :
soumis `yellow`, approuvé `green`, rejeté `red`, information `amber`, signé `indigo`.

## 7. Toasts et bandeaux

- Toast (`signaler`) : fond blanc, bord, ombre, `rounded-md` ; icône succès CheckCircle2
  `emerald-500`, erreur XCircle `red-500`, avertissement AlertTriangle `amber-500`, info Info `blue-500`.
- Bandeaux (`Bandeau`) : `bg-*-50 border-*-200 rounded-lg p-3`, icône `*-600`, texte `*-800` ;
  demande d'information reçue : `border-2 border-amber-300` (`fort: true`).
- Erreur de formulaire (`EncartErreur`) : `bg-red-50 border-red-200 rounded-md`, AlertCircle `red-600`.

## 8. Tableaux comparatif / explicatif

| Élément | Couleur | Flutter |
|---|---|---|
| En-tête BUDGET ETUDE | fond `#0261A7`, sous-en-têtes `#1E40AF` sur `#EFF6FF` | `Marque.tableauBudget*` |
| En-tête OBJECTIF | fond `#233861`, sous-en-têtes sur `#EEF2F9` | `Marque.tableauObjectif*` |
| Colonne lot / repère | `#6B7280` | `Marque.tableauLot` |
| Entreprise retenue | fond `#E8F5EE`, texte `#517A52` / `#2D7A52`, bord `#55AC79`, total `#517A52` | `Marque.retenu*` |
| Écart (Δ = budget − coût) | négatif `#DC2626`, sinon `#2D7A52` (retenue) / `#475569` | `Marque.ecartNegatif`, `ecartNeutre` |
| Ligne de section | fond `#EFF6FF`, liseré gauche 4 px `#0261A7`, texte `#0261A7` gras | `Marque.tableauSection` |
| Pied de tableau | fond `#0261A7`, texte blanc gras | |
| Explicatif : en-têtes de section | `bg-[#172D4C]` 11 px gras majuscules blanc | |
| Explicatif : cellules / pied | `#F1F7FC` / `#E3EEF8`, négatif `text-red-600` | `Marque.tableauCellule`, `tableauPied` |
| Marge | `text-green-700`, négative `text-red-600` | |

## 9. Typographie (`Typo`, IBM Plex Sans)

| Style | Web | Flutter |
|---|---|---|
| `affiche`, `compteur` | `text-2xl font-bold` | 24 / 700 |
| `titre` | `text-xl font-bold tracking-tight` | 20 / 700 |
| `sousTitre` | `text-lg font-bold` (titre de carte) | 18 / 700 |
| `corps` / `corpsFort` | `text-base` | 15 / 400–600 |
| `secondaire` / `libelle` | `text-sm` / `text-sm font-semibold` | 14 / 400–600 |
| `petit` / `sigle` | `text-xs font-medium` / `font-semibold` | 12 |
| `surTitre` | `text-[11px] font-semibold uppercase tracking-wide` | 11 / 600 |
| `code` | `font-mono text-sm font-bold tracking-wide` | IBM Plex Mono 13 / 700 |
| `montant*` | `font-semibold`/`font-extrabold tabular-nums` | chiffres tabulaires |

## 10. Formes

- Rayons : `--radius` 8 px → `rounded-md` 6 (boutons, champs, pastilles : `Rayon.s`),
  `rounded-lg` 8 (bandeaux, onglets : `Rayon.m`), `rounded-xl` 12 (cartes : `Rayon.l`).
- Ombres (`OmbreWeb`) : `shadow-xs`, `shadow-sm` (cartes), `shadow-md` (Approuver),
  panneau des tableaux de bord `0 10px 30px -5px rgba(23,45,76,.08)`.
- Boutons : hauteur 48 (`h-12` de la page de connexion), `rounded-md`, `font-semibold`.
- Champs : `h-12 border-2 border-gray-200 rounded-md`, focus `border-[#0061A7]`.

## 11. Icônes (Lucide)

Le web utilise `lucide-react` ; l'app utilise les **mêmes icônes** via `LucideIcons` (les anciens
noms du web restent disponibles : `checkCircle`, `xCircle`, `alertCircle`, `alertTriangle`,
`messageCircleQuestion`).

| Sens | Web | Flutter |
|---|---|---|
| Approuver / validé | CheckCircle | `LucideIcons.checkCircle` |
| Rejeter / rejeté | XCircle | `LucideIcons.xCircle` |
| En attente / en cours | Clock | `LucideIcons.clock` |
| Demande d'information | MessageCircleQuestion | `LucideIcons.messageCircleQuestion` |
| Message | MessageSquare | `LucideIcons.messageSquare` |
| Note | StickyNote | `LucideIcons.stickyNote` |
| Document RC | FileText | `LucideIcons.fileText` |
| Avenant | Layers | `LucideIcons.layers` |
| Consulter | Eye / EyeOff | `LucideIcons.eye` / `eyeOff` |
| Télécharger | Download | `LucideIcons.download` |
| Fichiers | Folder / FolderOpen | `LucideIcons.folder` / `folderOpen` |
| Suivre / parcours | ArrowRight | `LucideIcons.arrowRight`, `LucideIcons.route` |
| Bon de commande | ShoppingCart | `LucideIcons.shoppingCart` |
| Envoyer | Send | `LucideIcons.send` |
| Avertissement | AlertTriangle | `LucideIcons.alertTriangle` |
| Erreur | AlertCircle | `LucideIcons.alertCircle` |
| Info | Info | `LucideIcons.info` |
| Date / personne | Calendar / User | `LucideIcons.calendar` / `user` |
| Notifications | Bell / BellOff | `LucideIcons.bell` / `bellOff` |
| Déconnexion | LogOut | `LucideIcons.logOut` |
| Retour | ArrowLeft | `LucideIcons.arrowLeft` |
| Chargement | Loader2 | `Roue` |
| Tableau / Excel | Table / FileSpreadsheet | `LucideIcons.table` / `fileSpreadsheet` |
| Signature | — | `LucideIcons.signature` |
| Pièce jointe | Paperclip | `LucideIcons.paperclip` |
| Projet / entreprise | Building2 | `LucideIcons.building2` |

## 12. Images

| Web (`public/`) | Usage | App |
|---|---|---|
| `dgflow-logo-fond-blanc.png` | logo sur fond clair | `assets/images/logo-dgflow.png` |
| `dgflow-sidebar.png` | logo sur fond marine | `assets/images/logo-dgflow-dark.png` |
| `dg-group-logo.png` | page de connexion | `assets/images/dg-group-logo.png` |
| `dg-office-background.jpg` | visuel de connexion (flou + voile `rgb(23 45 76 / 48%)`) | `assets/images/dg-office-background.jpg` |
