import '../../core/network/api_client.dart';
import '../../core/network/api_contract.dart';
import '../models/json_utils.dart';
import '../models/playlist.dart';
import '../models/track.dart';

class PlaylistRepository {
  PlaylistRepository(this._api);

  final ApiClient _api;
  static const _pageSize = 50;

  /// All playlists (follows pagination, up to 10 pages). The list response only
  /// has `track_count`; tracks come from [tracksOf].
  Future<List<Playlist>> list() async {
    final out = <Playlist>[];
    for (var page = 1; page <= 10; page++) {
      final items = asList(await _api.get(Endpoints.playlists,
          query: {'page': page, 'page_size': _pageSize}));
      out.addAll(items
          .map((e) => Playlist.fromJson(asMap(e)))
          .where((p) => p.id.isNotEmpty));
      if (items.length < _pageSize) break;
    }
    return out;
  }

  /// GET /playlists/{id} -> metadata + ordered tracks.
  Future<List<Track>> tracksOf(String id) async =>
      Playlist.fromJson(asMap(await _api.get(Endpoints.playlist(id)))).tracks;

  Future<void> create(String name, String? description) =>
      _api.post(Endpoints.playlists, data: {
        Keys.playlistName: name.trim(),
        if (description != null && description.trim().isNotEmpty)
          Keys.playlistDescription: description.trim(),
      });

  Future<void> update(String id, String name, String? description) =>
      _api.patch(Endpoints.playlist(id), data: {
        Keys.playlistName: name.trim(),
        Keys.playlistDescription: (description ?? '').trim(),
      });

  Future<void> delete(String id) => _api.delete(Endpoints.playlist(id));

  Future<void> addTrack(String playlistId, String trackId) => _api.post(
      Endpoints.playlistTracks(playlistId),
      data: {Keys.trackId: trackId});

  Future<void> removeTrack(String playlistId, String trackId) =>
      _api.delete(Endpoints.playlistTrack(playlistId, trackId));
}
