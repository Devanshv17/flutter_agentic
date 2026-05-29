/// Typed argument accessor for tool executors.
///
/// Eliminates all manual casting from `Map<String, dynamic>`:
///
/// ```dart
/// // Before (error-prone):
/// final city = args['city'] as String;
/// final limit = (args['limit'] as num?)?.toInt() ?? 10;
///
/// // After (safe and readable):
/// final city  = args.string('city');
/// final limit = args.integer('limit', fallback: 10);
/// ```
library;

/// A strongly-typed wrapper around a raw `Map<String, dynamic>` argument map.
///
/// Automatically coerces types where safe (e.g. `num` → `int`, `int` → `double`).
/// Returns fallback values for missing/null keys instead of throwing.
class ToolArgs {
  final Map<String, dynamic> _raw;

  const ToolArgs(this._raw);

  // ── Primitive accessors ──────────────────────────────────────────────────

  /// Returns the string value for [key], or [fallback] if absent / null.
  String string(String key, {String fallback = ''}) =>
      _raw[key]?.toString() ?? fallback;

  /// Returns the int value for [key], or [fallback] if absent / null / non-numeric.
  int integer(String key, {int fallback = 0}) =>
      (_raw[key] as num?)?.toInt() ?? fallback;

  /// Returns the double value for [key], or [fallback] if absent / null / non-numeric.
  double number(String key, {double fallback = 0.0}) =>
      (_raw[key] as num?)?.toDouble() ?? fallback;

  /// Returns the bool value for [key], or [fallback] if absent / null.
  bool boolean(String key, {bool fallback = false}) =>
      _raw[key] as bool? ?? fallback;

  // ── Collection accessors ─────────────────────────────────────────────────

  /// Returns the list for [key], or an empty list if absent / null.
  List<T> list<T>(String key) => (_raw[key] as List?)?.cast<T>() ?? const [];

  /// Returns the nested map for [key], or an empty map if absent / null.
  Map<String, dynamic> map(String key) =>
      (_raw[key] as Map?)?.cast<String, dynamic>() ?? const {};

  /// Returns a [ToolArgs] wrapping the nested object at [key].
  ToolArgs nested(String key) => ToolArgs(map(key));

  /// Returns a list of [ToolArgs], one per item in the list at [key].
  List<ToolArgs> nestedList(String key) =>
      list<Map>(key).map((m) => ToolArgs(m.cast<String, dynamic>())).toList();

  // ── Nullable / optional accessors ────────────────────────────────────────

  /// Returns the value for [key] cast to [T], or null if absent / null.
  T? optional<T>(String key) {
    final v = _raw[key];
    if (v == null) return null;
    if (T == int && v is num) return v.toInt() as T;
    if (T == double && v is num) return v.toDouble() as T;
    return v as T?;
  }

  // ── Enum helpers ─────────────────────────────────────────────────────────

  /// Returns the string value for [key] if it is one of [allowed], else [fallback].
  ///
  /// ```dart
  /// final unit = args.oneOf('unit', ['celsius', 'fahrenheit'], fallback: 'celsius');
  /// ```
  String oneOf(String key, List<String> allowed, {required String fallback}) {
    final v = string(key, fallback: fallback);
    return allowed.contains(v) ? v : fallback;
  }

  // ── Inspection ───────────────────────────────────────────────────────────

  /// Returns true if [key] is present and non-null.
  bool has(String key) => _raw.containsKey(key) && _raw[key] != null;

  /// All argument keys provided by the LLM.
  Set<String> get keys => _raw.keys.toSet();

  /// The raw underlying map. Avoid this — use the typed accessors instead.
  Map<String, dynamic> get raw => Map.unmodifiable(_raw);

  /// Raw subscript access — useful for dynamic key lookups.
  dynamic operator [](String key) => _raw[key];

  @override
  String toString() => 'ToolArgs($_raw)';
}
