import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/track.dart';
import '../data/repositories/track_repository.dart';
import 'library_controller.dart';

/// Home-screen catalog: featured + all tracks, with a client-side category filter.
class CatalogController extends ChangeNotifier {
  CatalogController(this._repo);

  final TrackRepository _repo;

  LoadState state = LoadState.idle;
  String? error;
  List<Track> featured = [];
  List<Track> all = [];
  String? selectedCategory;

  /// Categories come from the track `genre`, falling back to the artist.
  List<String> get categories {
    final set = <String>{for (final t in all) t.genre ?? t.artist};
    return set.toList()..sort();
  }

  List<Track> get filtered => selectedCategory == null
      ? all
      : all.where((t) => (t.genre ?? t.artist) == selectedCategory).toList();

  Future<void> load() async {
    state = LoadState.loading;
    notifyListeners();
    try {
      final results = await Future.wait([_repo.featured(), _repo.all()]);
      featured = results[0];
      all = results[1];
      if (selectedCategory != null && !categories.contains(selectedCategory)) {
        selectedCategory = null;
      }
      state = LoadState.ready;
    } catch (e) {
      error = errorText(e);
      state = LoadState.error;
    }
    notifyListeners();
  }

  void selectCategory(String? c) {
    selectedCategory = selectedCategory == c ? null : c;
    notifyListeners();
  }

  void clear() {
    featured = [];
    all = [];
    selectedCategory = null;
    state = LoadState.idle;
    notifyListeners();
  }
}
