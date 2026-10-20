import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/models/commun.dart';
import 'jetons_web.dart';

export 'jetons_web.dart';

/// Famille de couleur Tailwind telle que le web l'emploie : `bg-*-100
/// text-*-800 border-*-300` pour une pastille, `bg-*-50 border-*-200` pour un
/// bandeau, `text-*-600` pour une icône ou un bouton contour, `*-500` pour un
/// liseré ou une pastille pleine.
@immutable
class Teinte {
  const Teinte({
    required this.fondDoux,
    required this.fond,
    required this.bordDoux,
    required this.bord,
    required this.plein,
    required this.vif,
    required this.fonce,
    required this.texte,
  });

  /// Nuances 50 → 800 en mode clair.
  const Teinte.clair({
    required Color c50,
    required Color c100,
    required Color c200,
    required Color c300,
    required Color c500,
    required Color c600,
    required Color c700,
    required Color c800,
  }) : fondDoux = c50,
       fond = c100,
       bordDoux = c200,
       bord = c300,
       plein = c500,
       vif = c600,
       fonce = c700,
       texte = c800;

  /// Équivalents sombres (idiome Tailwind `dark:bg-*-950 dark:text-*-200…`).
  const Teinte.sombre({
    required Color c200,
    required Color c400,
    required Color c500,
    required Color c700,
    required Color c900,
    required Color c950,
  }) : fondDoux = c950,
       fond = c900,
       bordDoux = c900,
       bord = c700,
       plein = c500,
       vif = c400,
       fonce = c500,
       texte = c200;

  /// `bg-*-50` : bandeaux, fonds de bloc.
  final Color fondDoux;

  /// `bg-*-100` : pastilles, cercles d'icône.
  final Color fond;

  /// `border-*-200` : bord des bandeaux.
  final Color bordDoux;

  /// `border-*-300` : bord des pastilles et des boutons contour.
  final Color bord;

  /// `*-500` : liseré gauche des cartes, pastilles pleines du parcours.
  final Color plein;

  /// `*-600` : icônes, texte des boutons contour, boutons pleins.
  final Color vif;

  /// `*-700` : fin de dégradé, appui.
  final Color fonce;

  /// `text-*-800` : texte des pastilles et des bandeaux.
  final Color texte;

  Teinte lerp(Teinte o, double t) {
    Color m(Color a, Color b) => Color.lerp(a, b, t)!;
    return Teinte(
      fondDoux: m(fondDoux, o.fondDoux),
      fond: m(fond, o.fond),
      bordDoux: m(bordDoux, o.bordDoux),
      bord: m(bord, o.bord),
      plein: m(plein, o.plein),
      vif: m(vif, o.vif),
      fonce: m(fonce, o.fonce),
      texte: m(texte, o.texte),
    );
  }
}

/// Jetons de design de l'application : ceux du web DG Flow (voir
/// `jetons_web.dart` et `docs/design-web.md`).
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.fond,
    required this.surface,
    required this.surfaceRelief,
    required this.bordure,
    required this.bordureForte,
    required this.texte,
    required this.titre,
    required this.texteSecondaire,
    required this.texteTertiaire,
    required this.texteDiscret,
    required this.marine,
    required this.marineProfond,
    required this.marineDegrade,
    required this.surMarine,
    required this.surMarineDoux,
    required this.action,
    required this.actionFonce,
    required this.surAction,
    required this.accentClair,
    required this.squelette,
    required this.gris,
    required this.bleu,
    required this.vert,
    required this.emeraude,
    required this.rouge,
    required this.orange,
    required this.ambre,
    required this.teal,
    required this.indigo,
    required this.violet,
  });

  /// Fond des pages (`bg-[#f6f7f8]`).
  final Color fond;

  /// Cartes, feuilles, dialogues (`bg-white`).
  final Color surface;

  /// Fonds secondaires : onglets, champs de recherche (`bg-gray-100`).
  final Color surfaceRelief;

  /// Bords des cartes et séparateurs (`border-gray-200`).
  final Color bordure;

  /// Bords appuyés, pointillés des états vides (`border-gray-300`).
  final Color bordureForte;

  /// Texte courant (`text-gray-900`).
  final Color texte;

  /// Titres de cartes et de sections (`text-[#172D4C]`).
  final Color titre;

  /// Texte secondaire (`text-gray-600`).
  final Color texteSecondaire;

  /// Texte tertiaire, dates (`text-gray-500`).
  final Color texteTertiaire;

  /// Icônes inactives (`text-gray-400`).
  final Color texteDiscret;

  /// En-têtes et barre de navigation (sidebar du web).
  final Color marine;
  final Color marineProfond;
  final Color marineDegrade;
  final Color surMarine;

  /// Texte atténué sur fond marine (`text-[#8BB1E0]`).
  final Color surMarineDoux;

  /// Bouton principal, liens, navigation active (`#0061A7`).
  final Color action;
  final Color actionFonce;
  final Color surAction;

  /// Fond teinté d'action (`bg-blue-50`, `bg-[#0061A7]/5`).
  final Color accentClair;
  final Color squelette;

  /// Familles Tailwind employées par les écrans RC.
  final Teinte gris;
  final Teinte bleu;
  final Teinte vert;
  final Teinte emeraude;
  final Teinte rouge;
  final Teinte orange;
  final Teinte ambre;
  final Teinte teal;
  final Teinte indigo;
  final Teinte violet;

  static const Palette clair = Palette(
    fond: Marque.fondPage,
    surface: Colors.white,
    surfaceRelief: Tw.gray100,
    bordure: Tw.gray200,
    bordureForte: Tw.gray300,
    texte: Tw.gray900,
    titre: Marque.marine,
    texteSecondaire: Tw.gray600,
    texteTertiaire: Tw.gray500,
    texteDiscret: Tw.gray400,
    marine: Marque.marine,
    marineProfond: Marque.marineBandeau,
    marineDegrade: Marque.marineDegrade,
    surMarine: Colors.white,
    surMarineDoux: Marque.bleuPale,
    action: Marque.bleu,
    actionFonce: Marque.bleuFonce,
    surAction: Colors.white,
    accentClair: Tw.blue50,
    squelette: Tw.gray200,
    gris: Teinte.clair(
      c50: Tw.gray50,
      c100: Tw.gray100,
      c200: Tw.gray200,
      c300: Tw.gray300,
      c500: Tw.gray500,
      c600: Tw.gray600,
      c700: Tw.gray700,
      c800: Tw.gray800,
    ),
    bleu: Teinte.clair(
      c50: Tw.blue50,
      c100: Tw.blue100,
      c200: Tw.blue200,
      c300: Tw.blue300,
      c500: Tw.blue500,
      c600: Tw.blue600,
      c700: Tw.blue700,
      c800: Tw.blue800,
    ),
    vert: Teinte.clair(
      c50: Tw.green50,
      c100: Tw.green100,
      c200: Tw.green200,
      c300: Tw.green300,
      c500: Tw.green500,
      c600: Tw.green600,
      c700: Tw.green700,
      c800: Tw.green800,
    ),
    emeraude: Teinte.clair(
      c50: Tw.emerald50,
      c100: Tw.emerald100,
      c200: Tw.emerald200,
      c300: Tw.emerald300,
      c500: Tw.emerald500,
      c600: Tw.emerald600,
      c700: Tw.emerald700,
      c800: Tw.emerald800,
    ),
    rouge: Teinte.clair(
      c50: Tw.red50,
      c100: Tw.red100,
      c200: Tw.red200,
      c300: Tw.red300,
      c500: Tw.red500,
      c600: Tw.red600,
      c700: Tw.red700,
      c800: Tw.red800,
    ),
    orange: Teinte.clair(
      c50: Tw.orange50,
      c100: Tw.orange100,
      c200: Tw.orange200,
      c300: Tw.orange300,
      c500: Tw.orange500,
      c600: Tw.orange600,
      c700: Tw.orange700,
      c800: Tw.orange800,
    ),
    ambre: Teinte.clair(
      c50: Tw.amber50,
      c100: Tw.amber100,
      c200: Tw.amber200,
      c300: Tw.amber300,
      c500: Tw.amber500,
      c600: Tw.amber600,
      c700: Tw.amber700,
      c800: Tw.amber800,
    ),
    teal: Teinte.clair(
      c50: Tw.teal50,
      c100: Tw.teal100,
      c200: Tw.teal200,
      c300: Tw.teal300,
      c500: Tw.teal500,
      c600: Tw.teal600,
      c700: Tw.teal700,
      c800: Tw.teal800,
    ),
    indigo: Teinte.clair(
      c50: Tw.indigo50,
      c100: Tw.indigo100,
      c200: Tw.indigo200,
      c300: Tw.indigo300,
      c500: Tw.indigo500,
      c600: Tw.indigo600,
      c700: Tw.indigo700,
      c800: Tw.indigo800,
    ),
    violet: Teinte.clair(
      c50: Tw.purple50,
      c100: Tw.purple100,
      c200: Tw.purple200,
      c300: Tw.purple300,
      c500: Tw.purple500,
      c600: Tw.purple600,
      c700: Tw.purple700,
      c800: Tw.purple800,
    ),
  );

  /// Mode sombre : jetons `.dark` de `globals.css` (gris neutres, `--primary`
  /// #4F8FCC) ; les en-têtes gardent le marine, comme les bandeaux du web.
  static const Palette sombre = Palette(
    fond: Shadcn.backgroundSombre,
    surface: Shadcn.sidebarSombre,
    surfaceRelief: Shadcn.mutedSombre,
    bordure: Shadcn.borderSombre,
    bordureForte: Tw.neutral700,
    texte: Shadcn.foregroundSombre,
    titre: Shadcn.foregroundSombre,
    texteSecondaire: Shadcn.mutedForegroundSombre,
    texteTertiaire: Tw.neutral500,
    texteDiscret: Tw.neutral600,
    marine: Marque.marine,
    marineProfond: Marque.marineBandeau,
    marineDegrade: Marque.marineDegrade,
    surMarine: Colors.white,
    surMarineDoux: Marque.bleuPale,
    action: Marque.bleuMoyen,
    actionFonce: Marque.bleuPale,
    surAction: Shadcn.backgroundSombre,
    accentClair: Tw.blue950,
    squelette: Shadcn.mutedSombre,
    gris: Teinte.sombre(
      c200: Tw.neutral200,
      c400: Tw.neutral400,
      c500: Tw.neutral500,
      c700: Tw.neutral700,
      c900: Tw.neutral800,
      c950: Tw.neutral900,
    ),
    bleu: Teinte.sombre(
      c200: Tw.blue200,
      c400: Tw.blue400,
      c500: Tw.blue500,
      c700: Tw.blue700,
      c900: Tw.blue900,
      c950: Tw.blue950,
    ),
    vert: Teinte.sombre(
      c200: Tw.green200,
      c400: Tw.green400,
      c500: Tw.green500,
      c700: Tw.green700,
      c900: Tw.green900,
      c950: Tw.green950,
    ),
    emeraude: Teinte.sombre(
      c200: Tw.emerald200,
      c400: Tw.emerald400,
      c500: Tw.emerald500,
      c700: Tw.emerald700,
      c900: Tw.emerald900,
      c950: Tw.emerald950,
    ),
    rouge: Teinte.sombre(
      c200: Tw.red200,
      c400: Tw.red400,
      c500: Tw.red500,
      c700: Tw.red700,
      c900: Tw.red900,
      c950: Tw.red950,
    ),
    orange: Teinte.sombre(
      c200: Tw.orange200,
      c400: Tw.orange400,
      c500: Tw.orange500,
      c700: Tw.orange700,
      c900: Tw.orange900,
      c950: Tw.orange950,
    ),
    ambre: Teinte.sombre(
      c200: Tw.amber200,
      c400: Tw.amber400,
      c500: Tw.amber500,
      c700: Tw.amber700,
      c900: Tw.amber900,
      c950: Tw.amber950,
    ),
    teal: Teinte.sombre(
      c200: Tw.teal200,
      c400: Tw.teal400,
      c500: Tw.teal500,
      c700: Tw.teal700,
      c900: Tw.teal900,
      c950: Tw.teal950,
    ),
    indigo: Teinte.sombre(
      c200: Tw.indigo200,
      c400: Tw.indigo400,
      c500: Tw.indigo500,
      c700: Tw.indigo700,
      c900: Tw.indigo900,
      c950: Tw.indigo950,
    ),
    violet: Teinte.sombre(
      c200: Tw.purple200,
      c400: Tw.purple400,
      c500: Tw.purple500,
      c700: Tw.purple700,
      c900: Tw.purple900,
      c950: Tw.purple950,
    ),
  );

  /// Ton de statut fourni par l'API (`lib/mobile/rc/statuts.ts`) → famille du
  /// web : brouillon gris, en attente bleu, validé SG émeraude, renvoi vers un
  /// autre rôle orange, rejet rouge (`RC_STATUS_CONFIG`, `RcValidation*.tsx`).
  Teinte ton(Ton t) => switch (t) {
    Ton.neutre => gris,
    Ton.info => bleu,
    Ton.succes => emeraude,
    Ton.alerte => orange,
    Ton.danger => rouge,
  };

  // Raccourcis sémantiques.
  Color get succes => vert.vif;
  Color get succesFond => vert.fond;
  Color get alerte => orange.vif;
  Color get alerteFond => orange.fond;
  Color get danger => rouge.vif;
  Color get dangerFond => rouge.fond;
  Color get info => action;
  Color get infoFond => accentClair;
  Color get neutre => texteSecondaire;
  Color get neutreFond => gris.fond;

  /// Bouton « Approuver et signer » (`from-green-600 to-green-700`).
  Color get approbation => vert.vif;

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(ThemeExtension<Palette>? other, double t) {
    if (other is! Palette) return this;
    Color m(Color a, Color b) => Color.lerp(a, b, t)!;
    return Palette(
      fond: m(fond, other.fond),
      surface: m(surface, other.surface),
      surfaceRelief: m(surfaceRelief, other.surfaceRelief),
      bordure: m(bordure, other.bordure),
      bordureForte: m(bordureForte, other.bordureForte),
      texte: m(texte, other.texte),
      titre: m(titre, other.titre),
      texteSecondaire: m(texteSecondaire, other.texteSecondaire),
      texteTertiaire: m(texteTertiaire, other.texteTertiaire),
      texteDiscret: m(texteDiscret, other.texteDiscret),
      marine: m(marine, other.marine),
      marineProfond: m(marineProfond, other.marineProfond),
      marineDegrade: m(marineDegrade, other.marineDegrade),
      surMarine: m(surMarine, other.surMarine),
      surMarineDoux: m(surMarineDoux, other.surMarineDoux),
      action: m(action, other.action),
      actionFonce: m(actionFonce, other.actionFonce),
      surAction: m(surAction, other.surAction),
      accentClair: m(accentClair, other.accentClair),
      squelette: m(squelette, other.squelette),
      gris: gris.lerp(other.gris, t),
      bleu: bleu.lerp(other.bleu, t),
      vert: vert.lerp(other.vert, t),
      emeraude: emeraude.lerp(other.emeraude, t),
      rouge: rouge.lerp(other.rouge, t),
      orange: orange.lerp(other.orange, t),
      ambre: ambre.lerp(other.ambre, t),
      teal: teal.lerp(other.teal, t),
      indigo: indigo.lerp(other.indigo, t),
      violet: violet.lerp(other.violet, t),
    );
  }
}

/// Polices du web (`globals.css`) : IBM Plex Sans partout, IBM Plex Mono pour
/// les codes (`font-mono`).
abstract final class Polices {
  static const String sans = 'IBMPlexSans';
  static const String mono = 'IBMPlexMono';
}

/// Échelle d'espacement Tailwind (1 unité = 4 px).
abstract final class Espace {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Rayons du web : `rounded-md` (boutons, champs, pastilles), `rounded-lg`
/// (bandeaux, onglets), `rounded-xl` (cartes).
abstract final class Rayon {
  static const double s = RayonWeb.md;
  static const double m = RayonWeb.lg;
  static const double l = RayonWeb.xl;
  static const double xl = 16;
}

/// Styles de texte, alignés sur l'échelle Tailwind du web (couleur appliquée
/// par le contexte). Chiffres tabulaires partout (`tabular-nums`) : les
/// montants s'alignent.
abstract final class Typo {
  /// Taille de tout le texte de l'application, réduite de 10 % par rapport à
  /// l'échelle ci-dessous (appliquée dans `DgFlowApp`, en plus du réglage de
  /// taille de police du téléphone).
  static const double echelle = 0.9;

  static const List<FontFeature> _chiffres = [FontFeature.tabularFigures()];

  /// `text-2xl font-bold` : valeur d'indicateur, phrase d'accueil.
  static const TextStyle affiche = TextStyle(
    fontFamily: Polices.sans,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    height: 1.3,
    letterSpacing: -0.2,
    fontFeatures: _chiffres,
  );

  /// `text-xl font-bold tracking-tight` : titre de page, de section.
  static const TextStyle titre = TextStyle(
    fontFamily: Polices.sans,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    height: 1.35,
    letterSpacing: -0.2,
    fontFeatures: _chiffres,
  );

  /// `text-lg font-bold` : titre de carte RC.
  static const TextStyle sousTitre = TextStyle(
    fontFamily: Polices.sans,
    fontWeight: FontWeight.w700,
    fontSize: 18,
    height: 1.4,
    fontFeatures: _chiffres,
  );

  /// Texte courant (`text-base`, un cran sous le web pour l'écran du téléphone).
  static const TextStyle corps = TextStyle(
    fontFamily: Polices.sans,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 1.5,
    fontFeatures: _chiffres,
  );
  static const TextStyle corpsFort = TextStyle(
    fontFamily: Polices.sans,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 1.5,
    fontFeatures: _chiffres,
  );

  /// `text-sm`.
  static const TextStyle secondaire = TextStyle(
    fontFamily: Polices.sans,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.43,
    fontFeatures: _chiffres,
  );

  /// `text-sm font-semibold` : libellés, intitulés de section.
  static const TextStyle libelle = TextStyle(
    fontFamily: Polices.sans,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 1.43,
    fontFeatures: _chiffres,
  );

  /// `text-xs font-medium`.
  static const TextStyle petit = TextStyle(
    fontFamily: Polices.sans,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 1.33,
    fontFeatures: _chiffres,
  );

  /// `text-[11px] font-semibold uppercase tracking-wide` : en-têtes de groupe.
  static const TextStyle surTitre = TextStyle(
    fontFamily: Polices.sans,
    fontWeight: FontWeight.w600,
    fontSize: 11,
    height: 1.3,
    letterSpacing: 0.4,
  );

  /// Boutons (`text-sm` → `text-base font-semibold` des boutons h-12 du web).
  static const TextStyle bouton = TextStyle(
    fontFamily: Polices.sans,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 1.25,
    fontFeatures: _chiffres,
  );

  /// Pastilles et sigles (`text-xs font-semibold`).
  static const TextStyle sigle = TextStyle(
    fontFamily: Polices.sans,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    height: 1.2,
    fontFeatures: _chiffres,
  );

  /// Codes et références (`font-mono text-sm font-bold tracking-wide`).
  static const TextStyle code = TextStyle(
    fontFamily: Polices.mono,
    fontWeight: FontWeight.w700,
    fontSize: 13,
    height: 1.35,
    letterSpacing: 0.3,
  );

  /// Montants : jamais en chasse fixe sur le web, `font-semibold tabular-nums`.
  static const TextStyle montant = TextStyle(
    fontFamily: Polices.sans,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.35,
    fontFeatures: _chiffres,
  );

  /// `text-lg font-extrabold tabular-nums` (« Montant de l'avenant »).
  static const TextStyle montantMoyen = TextStyle(
    fontFamily: Polices.sans,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    height: 1.3,
    fontFeatures: _chiffres,
  );
  static const TextStyle montantFort = TextStyle(
    fontFamily: Polices.sans,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    height: 1.2,
    letterSpacing: -0.3,
    fontFeatures: _chiffres,
  );

  /// Valeur d'indicateur (`text-2xl font-bold`).
  static const TextStyle compteur = TextStyle(
    fontFamily: Polices.sans,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    height: 1.2,
    fontFeatures: _chiffres,
  );
}

extension ContexteDg on BuildContext {
  Palette get dg => Theme.of(this).extension<Palette>()!;
  bool get sombre => Theme.of(this).brightness == Brightness.dark;
}

ThemeData construireTheme(Brightness luminosite) {
  final p = luminosite == Brightness.dark ? Palette.sombre : Palette.clair;
  final sombre = luminosite == Brightness.dark;
  final schema = ColorScheme(
    brightness: luminosite,
    primary: p.action,
    onPrimary: p.surAction,
    primaryContainer: p.accentClair,
    onPrimaryContainer: sombre ? p.texte : p.marine,
    secondary: sombre ? Marque.bleuPale : Marque.bleuMoyen,
    onSecondary: sombre ? p.fond : Colors.white,
    secondaryContainer: p.bleu.fond,
    onSecondaryContainer: p.bleu.texte,
    tertiary: p.ambre.vif,
    onTertiary: sombre ? p.fond : Colors.white,
    tertiaryContainer: p.ambre.fond,
    onTertiaryContainer: p.ambre.texte,
    error: p.danger,
    onError: sombre ? p.fond : Colors.white,
    errorContainer: p.rouge.fond,
    onErrorContainer: p.rouge.texte,
    surface: p.fond,
    onSurface: p.texte,
    onSurfaceVariant: p.texteSecondaire,
    surfaceContainerLowest: p.surface,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.surface,
    surfaceContainerHigh: p.surface,
    surfaceContainerHighest: p.surfaceRelief,
    outline: p.bordureForte,
    outlineVariant: p.bordure,
    inverseSurface: sombre ? p.texte : p.marine,
    onInverseSurface: sombre ? p.fond : Colors.white,
    inversePrimary: Marque.bleuPale,
    shadow: Colors.black,
    scrim: Colors.black,
  );

  final textes = TextTheme(
    displaySmall: Typo.affiche,
    headlineSmall: Typo.titre,
    titleLarge: Typo.sousTitre,
    titleMedium: Typo.libelle,
    titleSmall: Typo.libelle,
    bodyLarge: Typo.corps,
    bodyMedium: Typo.secondaire.copyWith(color: p.texteSecondaire),
    bodySmall: Typo.petit.copyWith(color: p.texteSecondaire),
    labelLarge: Typo.bouton,
    labelMedium: Typo.petit,
    labelSmall: Typo.petit,
  ).apply(bodyColor: p.texte, displayColor: p.texte);

  // Boutons du web : `rounded-md`, hauteur h-12 (48 px) comme ceux de la page de connexion.
  final forme = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rayon.s));
  OutlineInputBorder bord(Color c, [double l = 2]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(Rayon.s),
    borderSide: BorderSide(color: c, width: l),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: luminosite,
    colorScheme: schema,
    fontFamily: Polices.sans,
    textTheme: textes.copyWith(bodyMedium: Typo.secondaire.copyWith(color: p.texteSecondaire)),
    scaffoldBackgroundColor: p.fond,
    canvasColor: p.fond,
    extensions: [p],
    splashFactory: InkRipple.splashFactory,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    // En-tête des pages RC : bandeau marine, titre `text-xl font-bold text-white tracking-tight`.
    appBarTheme: AppBarTheme(
      backgroundColor: p.marine,
      foregroundColor: p.surMarine,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 4,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      titleTextStyle: Typo.titre.copyWith(color: p.surMarine),
      iconTheme: IconThemeData(color: p.surMarine, size: 22),
      actionsIconTheme: IconThemeData(color: p.surMarine, size: 22),
    ),
    // Barre d'onglets : la sidebar du web (fond marine, actif `bg-[#0061A7]`, inactif `#8BB1E0`).
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.marine,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Marque.bleu,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rayon.m)),
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => Typo.petit.copyWith(
          fontSize: 12.5,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? Colors.white : p.surMarineDoux,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? Colors.white : p.surMarineDoux, size: 22),
      ),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rayon.l),
        side: BorderSide(color: p.bordure),
      ),
    ),
    dividerTheme: DividerThemeData(color: p.bordure, thickness: 1, space: 1),
    // Bouton principal : `bg-[#0061A7] hover:bg-[#004d85] text-white font-semibold`.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: forme,
        textStyle: Typo.bouton,
        backgroundColor: p.action,
        foregroundColor: p.surAction,
        disabledBackgroundColor: p.action.withValues(alpha: 0.5),
        disabledForegroundColor: p.surAction.withValues(alpha: 0.85),
        elevation: 0,
      ),
    ),
    // Bouton contour shadcn : `border bg-background shadow-xs`, texte courant.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: forme,
        textStyle: Typo.bouton,
        foregroundColor: p.texte,
        side: BorderSide(color: p.bordure, width: 2),
        backgroundColor: p.surface,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 44),
        textStyle: Typo.libelle,
        foregroundColor: p.action,
        shape: forme,
      ),
    ),
    // Champs de la page de connexion : `h-12 border-2 border-gray-200 rounded-md`,
    // focus `border-[#0061A7]`.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: Espace.m, vertical: 13),
      hintStyle: Typo.corps.copyWith(color: p.texteTertiaire),
      labelStyle: Typo.corps.copyWith(color: p.texteSecondaire),
      border: bord(p.bordure),
      enabledBorder: bord(p.bordure),
      focusedBorder: bord(p.action),
      errorBorder: bord(p.rouge.plein),
      focusedErrorBorder: bord(p.rouge.plein),
      disabledBorder: bord(p.bordure),
      errorStyle: Typo.petit.copyWith(color: p.danger, fontSize: 13),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: p.surface,
      showDragHandle: true,
      dragHandleColor: p.bordureForte,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Rayon.xl))),
    ),
    // Dialogue shadcn : `rounded-lg border p-6 shadow-lg`, titre `text-lg font-semibold`.
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rayon.m),
        side: BorderSide(color: p.bordure),
      ),
      titleTextStyle: Typo.sousTitre.copyWith(color: p.titre, fontWeight: FontWeight.w600),
      contentTextStyle: Typo.secondaire.copyWith(color: p.texteSecondaire),
    ),
    // Toast du web : fond blanc, bord, `shadow-lg`, `rounded-md`.
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.surface,
      elevation: 6,
      contentTextStyle: Typo.secondaire.copyWith(color: p.texte, fontWeight: FontWeight.w500),
      actionTextColor: p.action,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rayon.s),
        side: BorderSide(color: p.bordure),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.action, linearTrackColor: p.bordure),
    // Compteur de non-lues : `bg-red-500 text-white text-[10px] font-bold rounded-full`.
    badgeTheme: BadgeThemeData(
      backgroundColor: p.rouge.plein,
      textColor: Colors.white,
      textStyle: Typo.petit.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.action : p.texteDiscret),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.action : null),
      side: BorderSide(color: p.bordureForte, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RayonWeb.sm)),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.action : p.bordure),
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    listTileTheme: ListTileThemeData(iconColor: p.action, textColor: p.texte, minVerticalPadding: 10),
    iconTheme: IconThemeData(color: p.texteSecondaire, size: 20),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: p.marine, borderRadius: BorderRadius.circular(Rayon.s)),
      textStyle: Typo.petit.copyWith(color: Colors.white),
    ),
    scrollbarTheme: const ScrollbarThemeData(thickness: WidgetStatePropertyAll(3)),
  );
}
