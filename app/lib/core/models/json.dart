/// Lecture tolérante du JSON de l'API.
///
/// Le contrat est typé côté serveur, mais Prisma peut sérialiser un `Decimal`
/// en chaîne et une colonne nullable peut manquer : ces aides acceptent les
/// deux formes plutôt que de faire échouer tout un écran.
library;

typedef Json = Map<String, dynamic>;

Json asJson(Object? v) => v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};

Json? asJsonOrNull(Object? v) => v is Map ? v.cast<String, dynamic>() : null;

String asString(Object? v, [String parDefaut = '']) => v == null ? parDefaut : v.toString();

String? asStringOrNull(Object? v) => v?.toString();

int? asIntOrNull(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? double.tryParse(v.trim())?.toInt();
  return null;
}

int asInt(Object? v, [int parDefaut = 0]) => asIntOrNull(v) ?? parDefaut;

double? asDoubleOrNull(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) {
    final d = double.tryParse(v.trim().replaceAll(',', '.'));
    return d != null && d.isFinite ? d : null;
  }
  return null;
}

double asDouble(Object? v, [double parDefaut = 0]) => asDoubleOrNull(v) ?? parDefaut;

bool asBool(Object? v, [bool parDefaut = false]) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == 'true' || v == '1';
  return parDefaut;
}

/// Dates ISO 8601 de l'API, rendues dans le fuseau du téléphone.
DateTime? asDateOrNull(Object? v) {
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is DateTime) return v.toLocal();
  return null;
}

DateTime asDate(Object? v) => asDateOrNull(v) ?? DateTime.fromMillisecondsSinceEpoch(0);

List<T> asList<T>(Object? v, T Function(Json) lire) =>
    v is List ? v.whereType<Map>().map((e) => lire(e.cast<String, dynamic>())).toList() : <T>[];
