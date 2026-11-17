import '../../core/network/api_client.dart';
import '../../core/network/api_contract.dart';
import '../../core/network/api_exception.dart';
import '../models/json_utils.dart';
import '../models/playlist.dart';
import '../models/track.dart';

class PlaylistRepository {
  PlaylistRepository(this._api);

  final ApiClient _api;

  Future<List<Playlist>> list() async {
    final body = await _api.get(Endpoints.playlists);
    return asList(body)
        .map((e) => Playlist.fromJson(asMap(e)))
        .where((p) => p.id.isNotEmpty)
        .toList();
  }

  /// Not in the documented endpoint table; used only when the list response
  /// does not embed tracks. A 404/405 just means "no detail endpoint".
  Future<List<Track>> tracksOf(String id) async {
    try {
      final body = await _api.get(Endpoints.playlist(id));
      return Playlist.fromJson(asMap(body)).tracks;
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) return const [];
      rethrow;
    }
  }

  Future<void> create(String name, String? description) =>
      _api.post(Endpoints.playlists, data: {
        Keys.playlistName: name.trim(),
        if (description != null && description.trim().isNotEmpty)
          Keys.playlistDescription: description.trim(),
      });

  /// The spec requires editing name/description, but the documented table has
  /// no update route. We try PATCH then PUT on /playlists/:id.
  Future<void> update(String id, String name, String? description) async {
    final data = {
      Keys.playlistName: name.trim(),
      Keys.playlistDescription: (description ?? '').trim(),
    };
    try {
      await _api.patch(Endpoints.playlist(id), data: data);
    } on ApiException catch (e) {
      if (e.statusCode == 405 || e.statusCode == 404) {
        await _api.put(Endpoints.playlist(id), data: data);
      } else {
        rethrow;
      }
    }
  }

  Future<void> delete(String id) => _api.delete(Endpoints.playlist(id));

  Future<void> addTrack(String playlistId, String trackId) => _api.post(
      Endpoints.playlistTracks(playlistId),
      data: {Keys.trackId: trackId});

  Future<void> removeTrack(String playlistId, String trackId) =>
      _api.delete(Endpoints.playlistTrack(playlistId, trackId));
}
