/// Defensive readers for API payloads.
///
/// Every value that arrives over the wire is treated as hostile: a field can be
/// missing, null, the wrong type, or a Prisma `Decimal` that serialises as a
/// string rather than a number. Parsing must never throw — a malformed row
/// should render as an empty card, not crash the gallery.
extension JsonMap on Map<String, dynamic> {
  String str(String key, [String fallback = '']) {
    final value = this[key];
    if (value is String) return value;
    if (value == null) return fallback;
    return value.toString();
  }

  String? strOrNull(String key) {
    final value = this[key];
    if (value is String) return value.isEmpty ? null : value;
    return null;
  }

  int intVal(String key, [int fallback = 0]) {
    final value = this[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  int? intOrNull(String key) {
    final value = this[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Prisma sends `Decimal` columns (`price_thb`, `cost_per_unit`) as strings.
  double dbl(String key, [double fallback = 0]) {
    final value = this[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  bool flag(String key, [bool fallback = false]) {
    final value = this[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value == 'true' || value == '1';
    return fallback;
  }

  DateTime? date(String key) {
    final value = this[key];
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }

  Map<String, dynamic>? obj(String key) {
    final value = this[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  /// `resultUrls` is a JSON column — a list, sometimes a single string, and
  /// null while a job is still running.
  List<String> strList(String key) {
    final value = this[key];
    if (value is List) {
      return value.whereType<Object>().map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    if (value is String && value.isNotEmpty) return [value];
    return const [];
  }

  List<Map<String, dynamic>> objList(String key) {
    final value = this[key];
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e))
        .toList();
  }
}
