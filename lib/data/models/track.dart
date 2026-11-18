import '../../core/config.dart';
import '../../core/network/api_contract.dart';
import 'json_utils.dart';

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.coverUrl,
    this.genre,
    this.duration,
    this.streamUrl,
  });

  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? coverUrl;
  final String? genre;
  final Duration? duration;
  final String? streamUrl;

  /// URL given by the server when present, otherwise the documented
  /// `/tracks/:id/stream` endpoint (supports HTTP 206 range requests).
  String get playUrl => streamUrl ?? '${AppConfig.baseUrl}${Endpoints.stream(id)}';

  factory Track.fromJson(Map<String, dynamic> j) {
    return Track(
      id: pickString(j, ResponseKeys.id) ?? '',
      title: pickString(j, ResponseKeys.title) ?? 'بدون عنوان',
      artist: pickString(j, ResponseKeys.artist) ?? 'نامشخص',
      album: pickString(j, ResponseKeys.album),
      coverUrl: absoluteUrl(pickString(j, ResponseKeys.cover)),
      genre: pickString(j, ResponseKeys.genre),
      duration: _parseDuration(j),
      streamUrl: absoluteUrl(pickString(j, ResponseKeys.streamUrl)),
    );
  }

  static Duration? _parseDuration(Map<dynamic, dynamic> j) {
    final ms = j['duration_ms'];
    if (ms is num) return Duration(milliseconds: ms.round());

    for (final k in const ['duration', 'duration_seconds', 'duration_sec', 'length']) {
      final v = j[k];
      if (v is num) {
        // Anything above 10h in "seconds" is almost certainly milliseconds.
        return v > 36000
            ? Duration(milliseconds: v.round())
            : Duration(milliseconds: (v * 1000).round());
      }
      if (v is String && v.isNotEmpty) {
        final n = num.tryParse(v);
        if (n != null) {
          return n > 36000
              ? Duration(milliseconds: n.round())
              : Duration(milliseconds: (n * 1000).round());
        }
        final parts = v.split(':').map(int.tryParse).toList();
        if (parts.isNotEmpty && !parts.contains(null)) {
          var secs = 0;
          for (final p in parts) {
            secs = secs * 60 + p!;
          }
          return Duration(seconds: secs);
        }
      }
    }
    return null;
  }

  /// Favorites endpoints may return `{ "track": {...} }` rows.
  static Track fromAny(dynamic item) {
    final m = asMap(item);
    final inner = m['track'];
    return Track.fromJson(inner is Map ? asMap(inner) : m);
  }

  @override
  bool operator ==(Object other) => other is Track && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
