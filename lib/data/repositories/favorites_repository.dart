import '../../core/network/api_client.dart';
import '../../core/network/api_contract.dart';
import '../../core/network/api_exception.dart';
import '../models/json_utils.dart';
import '../models/track.dart';

class FavoritesRepository {
  FavoritesRepository(this._api);

  final ApiClient _api;
  static const _pageSize = 50;

  /// All favorites (follows pagination, up to 10 pages).
  Future<List<Track>> list() async {
    final out = <Track>[];
    for (var page = 1; page <= 10; page++) {
      final items = asList(await _api.get(Endpoints.favorites,
          query: {'page': page, 'page_size': _pageSize}));
      out.addAll(items.map(Track.fromAny).where((t) => t.id.isNotEmpty));
      if (items.length < _pageSize) break;
    }
    return out;
  }

  Future<void> add(String trackId) async {
    try {
      await _api.post(Endpoints.favorites, data: {Keys.trackId: trackId});
    } on ApiException catch (e) {
      if (e.code == 'already_favorited') return; // already in the desired state
      rethrow;
    }
  }

  Future<void> remove(String trackId) =>
      _api.delete(Endpoints.favorite(trackId));
}
