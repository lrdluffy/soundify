import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/track.dart';
import '../data/repositories/track_repository.dart';
import 'library_controller.dart';

/// Home-screen catalog: featured tracks + the catalog, filterable by artist
/// (the filter runs on the server via `?artist=`).
class CatalogController extends ChangeNotifier {
  CatalogController(this._repo);

  final TrackRepository _repo;

  LoadState state = LoadState.idle;
  String? error;
  bool filtering = false;
  List<Track> featured = [];
  List<Track> all = [];
  List<String> categories = [];
  String? selectedCategory;

  List<Track> get filtered => all;

  Future<void> load() async {
    state = LoadState.loading;
    notifyListeners();
    try {
      final results = await Future.wait([_repo.featured(), _repo.all()]);
      featured = results[0];
      all = results[1];
      selectedCategory = null;
      categories = _topArtists(all);
      state = LoadState.ready;
    } catch (e) {
      error = errorText(e);
      state = LoadState.error;
    }
    notifyListeners();
  }

  /// The 12 most frequent artists of the first page act as category chips.
  List<String> _topArtists(List<Track> tracks) {
    final counts = <String, int>{};
    for (final t in tracks) {
      counts[t.artist] = (counts[t.artist] ?? 0) + 1;
    }
    final names = counts.keys.toList()
      ..sort((a, b) {
        final c = counts[b]!.compareTo(counts[a]!);
        return c != 0 ? c : a.compareTo(b);
      });
    return names.take(12).toList();
  }

  /// Tap a chip to filter, tap it again to clear. On failure the previous
  /// list and selection are kept.
  Future<void> selectCategory(String category) async {
    final previous = selectedCategory;
    selectedCategory = previous == category ? null : category;
    filtering = true;
    notifyListeners();
    try {
      all = await _repo.all(artist: selectedCategory);
    } catch (_) {
      selectedCategory = previous;
    }
    filtering = false;
    notifyListeners();
  }

  void clear() {
    featured = [];
    all = [];
    categories = [];
    selectedCategory = null;
    state = LoadState.idle;
    notifyListeners();
  }
}
