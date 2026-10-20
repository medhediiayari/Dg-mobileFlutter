/// Jetons graphiques du web DG Flow, relevés dans `dgflow/` :
///
/// - `app/globals.css` : couleurs de marque, jetons shadcn/ui (clair et sombre),
///   rayon `--radius: 0.5rem`, polices IBM Plex Sans / IBM Plex Mono ;
/// - classes Tailwind des écrans RC (`components/RcValidation*.tsx`,
///   `RcWorkflowDialog.tsx`, `TableauComparatif.tsx`, `Sidebar.tsx`…).
///
/// Le web est en Tailwind v4 : ses couleurs sont définies en oklch
/// (`node_modules/tailwindcss/theme.css`) ; les valeurs ci-dessous en sont la
/// conversion sRGB exacte. Toute couleur de l'application en dérive : ne pas
/// coder de couleur en dur ailleurs. Référence complète : `docs/design-web.md`.
library;

import 'package:flutter/material.dart';

/// Couleurs de marque DG Group (`globals.css` et valeurs littérales du web).
abstract final class Marque {
  /// `--primary` : sidebar, titres, en-têtes.
  static const Color marine = Color(0xFF172D4C);

  /// Bandeau des indicateurs (tableaux de bord par rôle).
  static const Color marineBandeau = Color(0xFF162C4B);

  /// Fin du dégradé des en-têtes de page RC (`from-[#172D4C] to-[#1e3d6b]`).
  static const Color marineDegrade = Color(0xFF1E3D6B);

  /// `--accent`, `--ring` : élément de navigation actif, liens, bouton principal.
  static const Color bleu = Color(0xFF0061A7);

  /// Survol du bouton principal (`hover:bg-[#004d85]`).
  static const Color bleuFonce = Color(0xFF004D85);

  /// `--secondary` ; `--primary` du mode sombre.
  static const Color bleuMoyen = Color(0xFF4F8FCC);

  /// Texte atténué de la sidebar, `--chart-4`, `--accent` du mode sombre.
  static const Color bleuPale = Color(0xFF8BB1E0);

  /// Fond des pages RC (`bg-[#f6f7f8]`).
  static const Color fondPage = Color(0xFFF6F7F8);

  /// Accent « à traiter » (`PendingWorkBadge.tsx`).
  static const Color cyanATraiter = Color(0xFF0E7490);

  // Tableau comparatif / explicatif (`TableauComparatif.tsx`, `TableauExplicatif.tsx`).
  static const Color tableauBudget = Color(0xFF0261A7);
  static const Color tableauBudgetSousTexte = Color(0xFF1E40AF);
  static const Color tableauBudgetSousFond = Color(0xFFEFF6FF);
  static const Color tableauObjectif = Color(0xFF233861);
  static const Color tableauObjectifSousFond = Color(0xFFEEF2F9);
  static const Color tableauLot = Color(0xFF6B7280);
  static const Color tableauSection = Color(0xFFEFF6FF);
  static const Color tableauCellule = Color(0xFFF1F7FC);
  static const Color tableauPied = Color(0xFFE3EEF8);

  /// Entreprise retenue (vert du tableau comparatif).
  static const Color retenu = Color(0xFF517A52);
  static const Color retenuFond = Color(0xFFE8F5EE);
  static const Color retenuTexte = Color(0xFF2D7A52);
  static const Color retenuBord = Color(0xFF55AC79);

  /// Écart négatif / neutre du tableau comparatif.
  static const Color ecartNegatif = Color(0xFFDC2626);
  static const Color ecartNeutre = Color(0xFF475569);
}

/// Jetons shadcn/ui de `globals.css` (`:root` et `.dark`), convertis d'oklch.
abstract final class Shadcn {
  // :root
  static const Color background = Color(0xFFFFFFFF);
  static const Color foreground = Color(0xFF0B0B0B);
  static const Color muted = Color(0xFFF5F5F5);
  static const Color mutedForeground = Color(0xFF555555);
  static const Color border = Color(0xFFDEDEDE);
  static const Color destructive = Color(0xFFE7000B);

  // .dark
  static const Color backgroundSombre = Color(0xFF0A0A0A);
  static const Color foregroundSombre = Color(0xFFFAFAFA);
  static const Color mutedSombre = Color(0xFF262626);
  static const Color mutedForegroundSombre = Color(0xFFA1A1A1);
  static const Color borderSombre = Color(0xFF262626);
  static const Color sidebarSombre = Color(0xFF171717);
  static const Color destructiveSombre = Color(0xFF82181A);
  static const Color destructiveForegroundSombre = Color(0xFFFB2C36);
}

/// Palette Tailwind v4 (nuances employées par le web), en sRGB.
abstract final class Tw {
  // gray
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DC);
  static const Color gray400 = Color(0xFF99A1AF);
  static const Color gray500 = Color(0xFF6A7282);
  static const Color gray600 = Color(0xFF4A5565);
  static const Color gray700 = Color(0xFF364153);
  static const Color gray800 = Color(0xFF1E2939);
  static const Color gray900 = Color(0xFF101828);
  static const Color gray950 = Color(0xFF030712);
  // slate
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCAD5E2);
  static const Color slate400 = Color(0xFF90A1B9);
  static const Color slate500 = Color(0xFF62748E);
  static const Color slate600 = Color(0xFF45556C);
  static const Color slate700 = Color(0xFF314158);
  static const Color slate800 = Color(0xFF1D293D);
  static const Color slate900 = Color(0xFF0F172B);
  static const Color slate950 = Color(0xFF020618);
  // neutral
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral400 = Color(0xFFA1A1A1);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF171717);
  static const Color neutral950 = Color(0xFF0A0A0A);
  // red
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red100 = Color(0xFFFFE2E2);
  static const Color red200 = Color(0xFFFFC9C9);
  static const Color red300 = Color(0xFFFFA2A2);
  static const Color red400 = Color(0xFFFF6467);
  static const Color red500 = Color(0xFFFB2C36);
  static const Color red600 = Color(0xFFE7000B);
  static const Color red700 = Color(0xFFC10007);
  static const Color red800 = Color(0xFF9F0712);
  static const Color red900 = Color(0xFF82181A);
  static const Color red950 = Color(0xFF460809);
  // orange
  static const Color orange50 = Color(0xFFFFF7ED);
  static const Color orange100 = Color(0xFFFFEDD4);
  static const Color orange200 = Color(0xFFFFD6A7);
  static const Color orange300 = Color(0xFFFFB86A);
  static const Color orange400 = Color(0xFFFF8904);
  static const Color orange500 = Color(0xFFFF6900);
  static const Color orange600 = Color(0xFFF54900);
  static const Color orange700 = Color(0xFFCA3500);
  static const Color orange800 = Color(0xFF9F2D00);
  static const Color orange900 = Color(0xFF7E2A0C);
  static const Color orange950 = Color(0xFF441306);
  // amber
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber100 = Color(0xFFFEF3C6);
  static const Color amber200 = Color(0xFFFEE685);
  static const Color amber300 = Color(0xFFFFD230);
  static const Color amber400 = Color(0xFFFFB900);
  static const Color amber500 = Color(0xFFFE9A00);
  static const Color amber600 = Color(0xFFE17100);
  static const Color amber700 = Color(0xFFBB4D00);
  static const Color amber800 = Color(0xFF973C00);
  static const Color amber900 = Color(0xFF7B3306);
  static const Color amber950 = Color(0xFF461901);
  // green
  static const Color green50 = Color(0xFFF0FDF4);
  static const Color green100 = Color(0xFFDCFCE7);
  static const Color green200 = Color(0xFFB9F8CF);
  static const Color green300 = Color(0xFF7BF1A8);
  static const Color green400 = Color(0xFF05DF72);
  static const Color green500 = Color(0xFF00C950);
  static const Color green600 = Color(0xFF00A63E);
  static const Color green700 = Color(0xFF008236);
  static const Color green800 = Color(0xFF016630);
  static const Color green900 = Color(0xFF0D542B);
  static const Color green950 = Color(0xFF032E15);
  // emerald
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald100 = Color(0xFFD0FAE5);
  static const Color emerald200 = Color(0xFFA4F4CF);
  static const Color emerald300 = Color(0xFF5EE9B5);
  static const Color emerald400 = Color(0xFF00D492);
  static const Color emerald500 = Color(0xFF00BC7D);
  static const Color emerald600 = Color(0xFF009966);
  static const Color emerald700 = Color(0xFF007A55);
  static const Color emerald800 = Color(0xFF006045);
  static const Color emerald900 = Color(0xFF004F3B);
  static const Color emerald950 = Color(0xFF002C22);
  // teal
  static const Color teal50 = Color(0xFFF0FDFA);
  static const Color teal100 = Color(0xFFCBFBF1);
  static const Color teal200 = Color(0xFF96F7E4);
  static const Color teal300 = Color(0xFF46ECD5);
  static const Color teal400 = Color(0xFF00D5BE);
  static const Color teal500 = Color(0xFF00BBA7);
  static const Color teal600 = Color(0xFF009689);
  static const Color teal700 = Color(0xFF00786F);
  static const Color teal800 = Color(0xFF005F5A);
  static const Color teal900 = Color(0xFF0B4F4A);
  static const Color teal950 = Color(0xFF022F2E);
  // cyan
  static const Color cyan50 = Color(0xFFECFEFF);
  static const Color cyan100 = Color(0xFFCEFAFE);
  static const Color cyan200 = Color(0xFFA2F4FD);
  static const Color cyan300 = Color(0xFF53EAFD);
  static const Color cyan400 = Color(0xFF00D3F2);
  static const Color cyan500 = Color(0xFF00B8DB);
  static const Color cyan600 = Color(0xFF0092B8);
  static const Color cyan700 = Color(0xFF007595);
  static const Color cyan800 = Color(0xFF005F78);
  static const Color cyan900 = Color(0xFF104E64);
  static const Color cyan950 = Color(0xFF053345);
  // sky
  static const Color sky50 = Color(0xFFF0F9FF);
  static const Color sky100 = Color(0xFFDFF2FE);
  static const Color sky200 = Color(0xFFB8E6FE);
  static const Color sky300 = Color(0xFF74D4FF);
  static const Color sky400 = Color(0xFF00BCFF);
  static const Color sky500 = Color(0xFF00A6F4);
  static const Color sky600 = Color(0xFF0084D1);
  static const Color sky700 = Color(0xFF0069A8);
  static const Color sky800 = Color(0xFF00598A);
  static const Color sky900 = Color(0xFF024A70);
  static const Color sky950 = Color(0xFF052F4A);
  // blue
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue200 = Color(0xFFBEDBFF);
  static const Color blue300 = Color(0xFF8EC5FF);
  static const Color blue400 = Color(0xFF51A2FF);
  static const Color blue500 = Color(0xFF2B7FFF);
  static const Color blue600 = Color(0xFF155DFC);
  static const Color blue700 = Color(0xFF1447E6);
  static const Color blue800 = Color(0xFF193CB8);
  static const Color blue900 = Color(0xFF1C398E);
  static const Color blue950 = Color(0xFF162456);
  // indigo
  static const Color indigo50 = Color(0xFFEEF2FF);
  static const Color indigo100 = Color(0xFFE0E7FF);
  static const Color indigo200 = Color(0xFFC6D2FF);
  static const Color indigo300 = Color(0xFFA3B3FF);
  static const Color indigo400 = Color(0xFF7C86FF);
  static const Color indigo500 = Color(0xFF615FFF);
  static const Color indigo600 = Color(0xFF4F39F6);
  static const Color indigo700 = Color(0xFF432DD7);
  static const Color indigo800 = Color(0xFF372AAC);
  static const Color indigo900 = Color(0xFF312C85);
  static const Color indigo950 = Color(0xFF1E1A4D);
  // violet
  static const Color violet50 = Color(0xFFF5F3FF);
  static const Color violet100 = Color(0xFFEDE9FE);
  static const Color violet200 = Color(0xFFDDD6FF);
  static const Color violet300 = Color(0xFFC4B4FF);
  static const Color violet400 = Color(0xFFA684FF);
  static const Color violet500 = Color(0xFF8E51FF);
  static const Color violet600 = Color(0xFF7F22FE);
  static const Color violet700 = Color(0xFF7008E7);
  static const Color violet800 = Color(0xFF5D0EC0);
  static const Color violet900 = Color(0xFF4D179A);
  static const Color violet950 = Color(0xFF2F0D68);
  // purple
  static const Color purple50 = Color(0xFFFAF5FF);
  static const Color purple100 = Color(0xFFF3E8FF);
  static const Color purple200 = Color(0xFFE9D4FF);
  static const Color purple300 = Color(0xFFDAB2FF);
  static const Color purple400 = Color(0xFFC27AFF);
  static const Color purple500 = Color(0xFFAD46FF);
  static const Color purple600 = Color(0xFF9810FA);
  static const Color purple700 = Color(0xFF8200DB);
  static const Color purple800 = Color(0xFF6E11B0);
  static const Color purple900 = Color(0xFF59168B);
  static const Color purple950 = Color(0xFF3C0366);
}

/// Rayons : `--radius` = 8 px ; `rounded-md` 6, `rounded-lg` 8, `rounded-xl` 12.
abstract final class RayonWeb {
  static const double sm = 4;
  static const double md = 6;
  static const double lg = 8;
  static const double xl = 12;
}

/// Ombres Tailwind v4.
abstract final class OmbreWeb {
  /// `shadow-xs` : boutons, champs.
  static const List<BoxShadow> xs = [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))];

  /// `shadow-sm` : cartes (shadcn Card), onglet actif.
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 2, spreadRadius: -1, offset: Offset(0, 1)),
  ];

  /// `shadow-md` : bouton « Approuver et signer ».
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 6, spreadRadius: -1, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 4, spreadRadius: -2, offset: Offset(0, 2)),
  ];

  /// Panneaux des tableaux de bord (`shadow-[0_10px_30px_-5px_rgba(23,45,76,0.08)]`).
  static const List<BoxShadow> panneau = [
    BoxShadow(color: Color(0x14172D4C), blurRadius: 30, spreadRadius: -5, offset: Offset(0, 10)),
  ];
}
