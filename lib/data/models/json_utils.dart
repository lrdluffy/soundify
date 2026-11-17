import '../../core/config.dart';

/// Pulls a list out of either `[...]` or `{ "items"|"data"|... : [...] }`.
List<dynamic> asList(dynamic d,
    [List<String> keys = const [
      'items',
      'results',
      'data',
      'tracks',
      'playlists',
      'favorites',
    ]]) {
  if (d is List) return d;
  if (d is Map) {
    for (final k in keys) {
      final v = d[k];
      if (v is List) return v;
    }
  }
  return const [];
}

/// First non-empty value among [keys]. Nested objects use their name/title.
String? pickString(Map<dynamic, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v == null) continue;
    if (v is Map) {
      final n = v['name'] ?? v['title'];
      if (n != null && n.toString().isNotEmpty) return n.toString();
      continue;
    }
    final s = v.toString();
    if (s.isNotEmpty) return s;
  }
  return null;
}

String? absoluteUrl(String? u) {
  if (u == null || u.isEmpty) return null;
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  return AppConfig.origin + (u.startsWith('/') ? u : '/$u');
}

Map<String, dynamic> asMap(dynamic d) =>
    d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
