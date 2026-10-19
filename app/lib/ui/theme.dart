import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/models/commun.dart';

/// Jetons de design — DG Flow RC.
///
/// Couleurs prélevées sur le logo DG Flow : les trois chevrons (clair, moyen,
/// profond) portent le fil du parcours ; le marine porte les en-têtes.
/// Typographie Barlow (signalétique routière, langue du chantier) ; la version
/// Semi Condensed porte titres, chiffres et sigles.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.fond,
    required this.surface,
    required this.surfaceRelief,
    required this.bordure,
    required this.texte,
    required this.texteSecondaire,
    required this.texteTertiaire,
    required this.marine,
    required this.marineProfond,
    required this.surMarine,
    required this.surMarineDoux,
    required this.action,
    required this.surAction,
    required this.accentClair,
    required this.chevronProfond,
    required this.chevronMoyen,
    required this.chevronClair,
    required this.chevronVide,
    required this.encreChevronVide,
    required this.succes,
    required this.succesFond,
    required this.alerte,
    required this.alerteFond,
    required this.danger,
    required this.dangerFond,
    required this.info,
    required this.infoFond,
    required this.neutre,
    required this.neutreFond,
    required this.squelette,
  });

  final Color fond;
  final Color surface;

  /// Surfaces secondaires (champs de recherche, segments, pastilles neutres).
  final Color surfaceRelief;
  final Color bordure;
  final Color texte;
  final Color texteSecondaire;
  final Color texteTertiaire;

  /// En-têtes.
  final Color marine;
  final Color marineProfond;
  final Color surMarine;
  final Color surMarineDoux;

  /// Actions, liens, étape en cours.
  final Color action;
  final Color surAction;
  final Color accentClair;

  /// Chevrons du logo : étape en cours / franchies / à revoir / à venir.
  final Color chevronProfond;
  final Color chevronMoyen;
  final Color chevronClair;
  final Color chevronVide;
  final Color encreChevronVide;

  final Color succes;
  final Color succesFond;
  final Color alerte;
  final Color alerteFond;
  final Color danger;
  final Color dangerFond;
  final Color info;
  final Color infoFond;
  final Color neutre;
  final Color neutreFond;
  final Color squelette;

  static const Palette clair = Palette(
    fond: Color(0xFFEEF2F8),
    surface: Color(0xFFFFFFFF),
    surfaceRelief: Color(0xFFE4EAF3),
    bordure: Color(0xFFDCE3EE),
    texte: Color(0xFF1A2540),
    texteSecondaire: Color(0xFF56637A),
    texteTertiaire: Color(0xFF7C8AA0),
    marine: Color(0xFF172D4C),
    marineProfond: Color(0xFF10223B),
    surMarine: Color(0xFFFFFFFF),
    surMarineDoux: Color(0xFFA2BAE0),
    action: Color(0xFF1D539D),
    surAction: Color(0xFFFFFFFF),
    accentClair: Color(0xFFE8EEF8),
    chevronProfond: Color(0xFF1D539D),
    chevronMoyen: Color(0xFF507EBC),
    chevronClair: Color(0xFFA2BAE0),
    chevronVide: Color(0xFFE1E8F3),
    encreChevronVide: Color(0xFF7C8AA0),
    succes: Color(0xFF1A7A4C),
    succesFond: Color(0xFFE3F3EA),
    alerte: Color(0xFFA9560B),
    alerteFond: Color(0xFFFCEFDF),
    danger: Color(0xFFB42318),
    dangerFond: Color(0xFFFCEBE9),
    info: Color(0xFF1D539D),
    infoFond: Color(0xFFE8EEF8),
    neutre: Color(0xFF56637A),
    neutreFond: Color(0xFFEDF0F5),
    squelette: Color(0xFFE3E9F2),
  );

  /// Mode sombre : le marine du logo devient le fond de nuit de chantier.
  static const Palette sombre = Palette(
    fond: Color(0xFF0E1A2B),
    surface: Color(0xFF15243A),
    surfaceRelief: Color(0xFF1D2F49),
    bordure: Color(0xFF263B58),
    texte: Color(0xFFE6ECF5),
    texteSecondaire: Color(0xFFA5B3C8),
    texteTertiaire: Color(0xFF7D8DA6),
    marine: Color(0xFF172D4C),
    marineProfond: Color(0xFF12243E),
    surMarine: Color(0xFFFFFFFF),
    surMarineDoux: Color(0xFFA2BAE0),
    action: Color(0xFF8DB4EC),
    surAction: Color(0xFF0C2442),
    accentClair: Color(0xFF1B3354),
    chevronProfond: Color(0xFF2F6BC0),
    chevronMoyen: Color(0xFF507EBC),
    chevronClair: Color(0xFF34507A),
    chevronVide: Color(0xFF223550),
    encreChevronVide: Color(0xFF7D8DA6),
    succes: Color(0xFF6CD3A0),
    succesFond: Color(0xFF12352A),
    alerte: Color(0xFFF2B46B),
    alerteFond: Color(0xFF3A2A14),
    danger: Color(0xFFF4978E),
    dangerFond: Color(0xFF40201E),
    info: Color(0xFF8DB4EC),
    infoFond: Color(0xFF1B3354),
    neutre: Color(0xFFA5B3C8),
    neutreFond: Color(0xFF1F2F46),
    squelette: Color(0xFF1E2F47),
  );

  /// Couleur du texte et du fond d'un ton de pastille.
  ({Color texte, Color fond}) ton(Ton t) => switch (t) {
    Ton.neutre => (texte: neutre, fond: neutreFond),
    Ton.info => (texte: info, fond: infoFond),
    Ton.succes => (texte: succes, fond: succesFond),
    Ton.alerte => (texte: alerte, fond: alerteFond),
    Ton.danger => (texte: danger, fond: dangerFond),
  };

  /// Bouton d'approbation : vert franc, lisible en plein soleil.
  Color get approbation => const Color(0xFF1A7A4C);

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
      texte: m(texte, other.texte),
      texteSecondaire: m(texteSecondaire, other.texteSecondaire),
      texteTertiaire: m(texteTertiaire, other.texteTertiaire),
      marine: m(marine, other.marine),
      marineProfond: m(marineProfond, other.marineProfond),
      surMarine: m(surMarine, other.surMarine),
      surMarineDoux: m(surMarineDoux, other.surMarineDoux),
      action: m(action, other.action),
      surAction: m(surAction, other.surAction),
      accentClair: m(accentClair, other.accentClair),
      chevronProfond: m(chevronProfond, other.chevronProfond),
      chevronMoyen: m(chevronMoyen, other.chevronMoyen),
      chevronClair: m(chevronClair, other.chevronClair),
      chevronVide: m(chevronVide, other.chevronVide),
      encreChevronVide: m(encreChevronVide, other.encreChevronVide),
      succes: m(succes, other.succes),
      succesFond: m(succesFond, other.succesFond),
      alerte: m(alerte, other.alerte),
      alerteFond: m(alerteFond, other.alerteFond),
      danger: m(danger, other.danger),
      dangerFond: m(dangerFond, other.dangerFond),
      info: m(info, other.info),
      infoFond: m(infoFond, other.infoFond),
      neutre: m(neutre, other.neutre),
      neutreFond: m(neutreFond, other.neutreFond),
      squelette: m(squelette, other.squelette),
    );
  }
}

abstract final class Polices {
  static const String barlow = 'Barlow';
  static const String condensee = 'BarlowSemiCondensed';
}

abstract final class Espace {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class Rayon {
  static const double s = 6;
  static const double m = 10;
  static const double l = 16;
  static const double xl = 22;
}

/// Styles de texte (couleur appliquée par le contexte).
abstract final class Typo {
  /// Chiffres tabulaires partout : les montants s'alignent, et le crénage de
  /// Barlow ne « mange » plus l'espace fine insécable qui suit un 1 (« 1 135 355 »).
  static const List<FontFeature> _chiffres = [FontFeature.tabularFigures()];

  /// Phrase d'accueil « 3 documents attendent votre décision ».
  static const TextStyle affiche = TextStyle(
    fontFamily: Polices.condensee,
    fontWeight: FontWeight.w600,
    fontSize: 31,
    height: 1.1,
    letterSpacing: -0.2,
    fontFeatures: _chiffres,
  );
  static const TextStyle titre = TextStyle(
    fontFamily: Polices.condensee,
    fontWeight: FontWeight.w600,
    fontSize: 24,
    height: 1.17,
    fontFeatures: _chiffres,
  );
  static const TextStyle sousTitre = TextStyle(
    fontFamily: Polices.condensee,
    fontWeight: FontWeight.w600,
    fontSize: 19,
    height: 1.22,
    fontFeatures: _chiffres,
  );
  static const TextStyle corps = TextStyle(
    fontFamily: Polices.barlow,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.38,
    fontFeatures: _chiffres,
  );
  static const TextStyle corpsFort = TextStyle(
    fontFamily: Polices.barlow,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.38,
    fontFeatures: _chiffres,
  );
  static const TextStyle secondaire = TextStyle(
    fontFamily: Polices.barlow,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.36,
    fontFeatures: _chiffres,
  );
  static const TextStyle libelle = TextStyle(
    fontFamily: Polices.barlow,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 1.33,
    fontFeatures: _chiffres,
  );
  static const TextStyle petit = TextStyle(
    fontFamily: Polices.barlow,
    fontWeight: FontWeight.w500,
    fontSize: 12.5,
    height: 1.3,
    fontFeatures: _chiffres,
  );
  static const TextStyle bouton = TextStyle(
    fontFamily: Polices.barlow,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.25,
    fontFeatures: _chiffres,
  );
  static const TextStyle sigle = TextStyle(
    fontFamily: Polices.condensee,
    fontWeight: FontWeight.w700,
    fontSize: 14,
    height: 1.1,
    fontFeatures: _chiffres,
  );
  static const TextStyle montant = TextStyle(
    fontFamily: Polices.condensee,
    fontWeight: FontWeight.w600,
    fontSize: 17,
    height: 1.24,
    fontFeatures: _chiffres,
  );
  static const TextStyle montantMoyen = TextStyle(
    fontFamily: Polices.condensee,
    fontWeight: FontWeight.w600,
    fontSize: 21,
    height: 1.2,
    fontFeatures: _chiffres,
  );
  static const TextStyle montantFort = TextStyle(
    fontFamily: Polices.condensee,
    fontWeight: FontWeight.w600,
    fontSize: 32,
    height: 1.1,
    letterSpacing: -0.3,
    fontFeatures: _chiffres,
  );
  static const TextStyle compteur = TextStyle(
    fontFamily: Polices.condensee,
    fontWeight: FontWeight.w600,
    fontSize: 26,
    height: 1.1,
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
    secondary: p.chevronMoyen,
    onSecondary: Colors.white,
    secondaryContainer: p.chevronVide,
    onSecondaryContainer: p.texte,
    tertiary: p.alerte,
    onTertiary: sombre ? p.fond : Colors.white,
    tertiaryContainer: p.alerteFond,
    onTertiaryContainer: p.alerte,
    error: p.danger,
    onError: sombre ? p.fond : Colors.white,
    errorContainer: p.dangerFond,
    onErrorContainer: p.danger,
    surface: p.fond,
    onSurface: p.texte,
    onSurfaceVariant: p.texteSecondaire,
    surfaceContainerLowest: p.surface,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.surface,
    surfaceContainerHigh: p.surface,
    surfaceContainerHighest: p.surfaceRelief,
    outline: p.texteTertiaire,
    outlineVariant: p.bordure,
    inverseSurface: sombre ? p.texte : p.marine,
    onInverseSurface: sombre ? p.fond : Colors.white,
    inversePrimary: p.chevronClair,
    shadow: Colors.black,
    scrim: const Color(0xFF0B1626),
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

  final forme = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rayon.m));

  return ThemeData(
    useMaterial3: true,
    brightness: luminosite,
    colorScheme: schema,
    fontFamily: Polices.barlow,
    textTheme: textes.copyWith(bodyMedium: Typo.secondaire.copyWith(color: p.texteSecondaire)),
    scaffoldBackgroundColor: p.fond,
    canvasColor: p.fond,
    extensions: [p],
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.marine,
      foregroundColor: p.surMarine,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 4,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      titleTextStyle: Typo.sousTitre.copyWith(fontSize: 21, color: p.surMarine),
      iconTheme: IconThemeData(color: p.surMarine),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.accentClair,
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => Typo.petit.copyWith(
          fontSize: 12.5,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? p.action : p.texteSecondaire,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? p.action : p.texteSecondaire, size: 24),
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
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: forme,
        textStyle: Typo.bouton,
        backgroundColor: p.action,
        foregroundColor: p.surAction,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: forme,
        textStyle: Typo.bouton,
        foregroundColor: p.action,
        side: BorderSide(color: p.bordure),
        backgroundColor: p.surface,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: Typo.bouton.copyWith(fontSize: 15),
        foregroundColor: p.action,
        shape: forme,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: Espace.m + 2, vertical: 15),
      hintStyle: Typo.corps.copyWith(color: p.texteTertiaire),
      labelStyle: Typo.corps.copyWith(color: p.texteSecondaire),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Rayon.m),
        borderSide: BorderSide(color: p.bordure),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Rayon.m),
        borderSide: BorderSide(color: p.bordure),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Rayon.m),
        borderSide: BorderSide(color: p.action, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Rayon.m),
        borderSide: BorderSide(color: p.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Rayon.m),
        borderSide: BorderSide(color: p.danger, width: 2),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.fond,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: p.fond,
      showDragHandle: true,
      dragHandleColor: p.texteTertiaire,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Rayon.xl + 4))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rayon.l + 4)),
      titleTextStyle: Typo.sousTitre.copyWith(color: p.texte, fontSize: 21),
      contentTextStyle: Typo.corps.copyWith(color: p.texteSecondaire),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: sombre ? p.surfaceRelief : p.marine,
      contentTextStyle: Typo.corps.copyWith(color: Colors.white, fontSize: 15),
      actionTextColor: p.surMarineDoux,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rayon.m)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.action, linearTrackColor: p.chevronVide),
    badgeTheme: BadgeThemeData(
      backgroundColor: p.danger,
      textColor: Colors.white,
      textStyle: Typo.petit.copyWith(fontSize: 11),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.action : p.texteTertiaire),
    ),
    listTileTheme: ListTileThemeData(iconColor: p.action, textColor: p.texte, minVerticalPadding: 10),
    iconTheme: IconThemeData(color: p.texteSecondaire),
    scrollbarTheme: const ScrollbarThemeData(thickness: WidgetStatePropertyAll(3)),
  );
}
