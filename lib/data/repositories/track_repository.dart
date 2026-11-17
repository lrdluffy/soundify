import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_contract.dart';
import '../models/json_utils.dart';
import '../models/track.dart';

class TrackRepository {
  TrackRepository(this._api);

  final ApiClient _api;

  List<Track> _parse(dynamic body) =>
      asList(body).map(Track.fromAny).where((t) => t.id.isNotEmpty).toList();

  Future<List<Track>> featured() async =>
      _parse(await _api.get(Endpoints.featured, auth: false));

  Future<List<Track>> all() async =>
      _parse(await _api.get(Endpoints.tracks, auth: false));

  Future<List<Track>> search(String query, {CancelToken? cancel}) async =>
      _parse(await _api.get(Endpoints.tracks,
          query: {'q': query}, auth: false, cancel: cancel));
}
