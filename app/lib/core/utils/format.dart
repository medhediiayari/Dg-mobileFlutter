import 'package:intl/intl.dart';

/// Formats français, alignés sur `mobile/src/utils/format.ts` (Intl fr-FR) :
/// séparateur de milliers = espace fine insécable (U+202F), espace insécable
/// (U+00A0) avant le symbole €.
abstract final class Format {
  static const String espaceFine = ' ';
  static const String espaceInsecable = ' ';
  static const String tiret = '—';

  static final NumberFormat _nombre = NumberFormat('#,##0.##', 'fr_FR');
  static final NumberFormat _deuxDecimales = NumberFormat('#,##0.00', 'fr_FR');
  static final NumberFormat _entier = NumberFormat('#,##0', 'fr_FR');

  /// Normalise les séparateurs produits par intl (selon la version des données CLDR).
  static String _normaliser(String s) => s.replaceAll(' ', espaceFine).replaceAll(espaceInsecable, espaceFine);

  /// « 1 234,50 € » ; arrondi : « 1 235 € ». « — » si absent.
  static String euros(num? v, {bool arrondi = false}) {
    if (v == null || !v.isFinite) return tiret;
    final corps = _normaliser((arrondi ? _entier : _deuxDecimales).format(v));
    // « -0 € » n'a pas de sens.
    final net = corps == '-0' || corps == '-0,00' ? corps.substring(1) : corps;
    return '$net$espaceInsecable€';
  }

  /// Écart signé : « +1 200,00 € », « -3 400,00 € ».
  static String eurosSignes(num? v, {bool arrondi = false}) {
    if (v == null || !v.isFinite) return tiret;
    return v > 0 ? '+${euros(v, arrondi: arrondi)}' : euros(v, arrondi: arrondi);
  }

  static String nombre(num? v) {
    if (v == null || !v.isFinite) return tiret;
    return _normaliser(_nombre.format(v));
  }

  static String pourcentage(num? v) {
    if (v == null || !v.isFinite) return tiret;
    return '${nombre(v)} %';
  }

  static String date(DateTime? d) {
    if (d == null) return tiret;
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(d);
  }

  /// Date ISO (chaîne de l'API) ; rendue telle quelle si illisible.
  static String dateIso(String? iso) {
    if (iso == null || iso.isEmpty) return tiret;
    final d = DateTime.tryParse(iso);
    return d == null ? iso : date(d.toLocal());
  }

  static String dateHeure(DateTime? d) {
    if (d == null) return tiret;
    return '${date(d)} à ${DateFormat('HH:mm', 'fr_FR').format(d)}';
  }

  static String heure(DateTime d) => DateFormat('HH:mm', 'fr_FR').format(d);

  /// « 3 oct. »
  static String jourMois(DateTime d) => DateFormat('d MMM', 'fr_FR').format(d);

  /// « à l'instant », « il y a 5 min », « il y a 3 h », « hier », « il y a 4 j », sinon la date.
  static String relatif(DateTime? d, {DateTime? maintenant}) {
    if (d == null) return '';
    final s = (maintenant ?? DateTime.now()).difference(d).inSeconds;
    if (s < 60) return "à l'instant";
    if (s < 3600) return 'il y a ${s ~/ 60} min';
    if (s < 86400) return 'il y a ${s ~/ 3600} h';
    if (s < 2 * 86400) return 'hier';
    if (s < 7 * 86400) return 'il y a ${s ~/ 86400} j';
    return date(d);
  }

  /// « 512 o », « 48 Ko », « 2,2 Mo ».
  static String taille(int octets) {
    if (octets < 1024) return '$octets o';
    if (octets < 1024 * 1024) return '${(octets / 1024).round()} Ko';
    return '${(octets / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} Mo';
  }

  /// Compare deux versions « x.y.z » : a < b ?
  static bool versionInferieure(String a, String b) {
    List<int> parties(String v) =>
        v.split('.').map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9].*$'), '')) ?? 0).toList();
    final pa = parties(a);
    final pb = parties(b);
    for (var i = 0; i < 3; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x < y) return true;
      if (x > y) return false;
    }
    return false;
  }

  /// Pluriel simple : « 1 document », « 3 documents ».
  static String pluriel(int n, String singulier, [String? pluriel]) =>
      '$n ${n > 1 ? (pluriel ?? '${singulier}s') : singulier}';
}
