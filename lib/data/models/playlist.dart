import '../../core/network/api_contract.dart';
import 'json_utils.dart';
import 'track.dart';

class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    this.description,
    this.tracks = const [],
    this.trackCount,
  });

  final String id;
  final String name;
  final String? description;
  final List<Track> tracks;
  final int? trackCount;

  int get count => trackCount ?? tracks.length;

  factory Playlist.fromJson(Map<String, dynamic> j) {
    final raw = j['tracks'] ?? j['items'];
    final tracks = raw is List ? raw.map(Track.fromAny).toList() : <Track>[];
    final count = j['track_count'] ?? j['tracks_count'] ?? j['count'];
    return Playlist(
      id: pickString(j, ResponseKeys.id) ?? '',
      name: pickString(j, const ['name', 'title']) ?? 'بدون نام',
      description: pickString(j, const ['description']),
      tracks: tracks,
      trackCount: count is num ? count.toInt() : null,
    );
  }
}
