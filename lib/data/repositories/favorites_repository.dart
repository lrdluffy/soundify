import '../../core/network/api_client.dart';
import '../../core/network/api_contract.dart';
import '../models/json_utils.dart';
import '../models/track.dart';

class FavoritesRepository {
  FavoritesRepository(this._api);

  final ApiClient _api;

  Future<List<Track>> list() async => asList(await _api.get(Endpoints.favorites))
      .map(Track.fromAny)
      .where((t) => t.id.isNotEmpty)
      .toList();

  Future<void> add(String trackId) =>
      _api.post(Endpoints.favorites, data: {Keys.trackId: trackId});

  Future<void> remove(String trackId) =>
      _api.delete(Endpoints.favorite(trackId));
}
