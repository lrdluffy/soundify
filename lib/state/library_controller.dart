import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/playlist.dart';
import '../data/models/track.dart';
import '../data/repositories/favorites_repository.dart';
import '../data/repositories/playlist_repository.dart';

enum LoadState { idle, loading, ready, error }

/// Playlists + favorites, kept in sync with the server. Likes are optimistic
/// and roll back if the server call fails.
class LibraryController extends ChangeNotifier {
  LibraryController(this._playlists, this._favorites);

  final PlaylistRepository _playlists;
  final FavoritesRepository _favorites;

  LoadState playlistsState = LoadState.idle;
  LoadState favoritesState = LoadState.idle;
  String? playlistsError;
  String? favoritesError;

  List<Playlist> playlists = [];
  List<Track> favorites = [];
  final Set<String> _favoriteIds = {};

  bool isFavorite(String trackId) => _favoriteIds.contains(trackId);

  Future<void> loadAll() => Future.wait([loadPlaylists(), loadFavorites()]);

  Future<void> loadPlaylists() async {
    playlistsState = LoadState.loading;
    notifyListeners();
    try {
      playlists = await _playlists.list();
      playlistsState = LoadState.ready;
    } catch (e) {
      playlistsError = errorText(e);
      playlistsState = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    favoritesState = LoadState.loading;
    notifyListeners();
    try {
      favorites = await _favorites.list();
      _favoriteIds
        ..clear()
        ..addAll(favorites.map((t) => t.id));
      favoritesState = LoadState.ready;
    } catch (e) {
      favoritesError = errorText(e);
      favoritesState = LoadState.error;
    }
    notifyListeners();
  }

  /// Throws ApiException on failure (after rolling back).
  Future<void> toggleFavorite(Track track) async {
    final wasFav = isFavorite(track.id);
    final oldList = List<Track>.of(favorites);

    if (wasFav) {
      _favoriteIds.remove(track.id);
      favorites = favorites.where((t) => t.id != track.id).toList();
    } else {
      _favoriteIds.add(track.id);
      favorites = [track, ...favorites];
    }
    notifyListeners();

    try {
      wasFav ? await _favorites.remove(track.id) : await _favorites.add(track.id);
    } catch (e) {
      favorites = oldList;
      _favoriteIds
        ..clear()
        ..addAll(oldList.map((t) => t.id));
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createPlaylist(String name, String? description) async {
    await _playlists.create(name, description);
    await loadPlaylists();
  }

  Future<void> updatePlaylist(String id, String name, String? description) async {
    await _playlists.update(id, name, description);
    await loadPlaylists();
  }

  Future<void> deletePlaylist(String id) async {
    await _playlists.delete(id);
    playlists = playlists.where((p) => p.id != id).toList();
    notifyListeners();
  }

  Future<void> addToPlaylist(String playlistId, Track track) async {
    await _playlists.addTrack(playlistId, track.id);
    await loadPlaylists();
  }

  Future<void> removeFromPlaylist(String playlistId, String trackId) async {
    await _playlists.removeTrack(playlistId, trackId);
    await loadPlaylists();
  }

  /// Tracks of a playlist: embedded in the list response if available,
  /// otherwise fetched on demand.
  Future<List<Track>> tracksOf(Playlist p) async {
    if (p.tracks.isNotEmpty || p.count == 0) return p.tracks;
    return _playlists.tracksOf(p.id);
  }

  void clear() {
    playlists = [];
    favorites = [];
    _favoriteIds.clear();
    playlistsState = LoadState.idle;
    favoritesState = LoadState.idle;
    notifyListeners();
  }
}
