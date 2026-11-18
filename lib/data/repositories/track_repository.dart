import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_contract.dart';
import '../models/json_utils.dart';
import '../models/track.dart';

class TrackRepository {
  TrackRepository(this._api);

  final ApiClient _api;

  /// The API caps page_size at 50.
  static const pageSize = 50;

  List<Track> _parse(dynamic body) =>
      asList(body).map(Track.fromAny).where((t) => t.id.isNotEmpty).toList();

  Future<List<Track>> featured() async => _parse(await _api.get(
      Endpoints.featured,
      query: {'page': 1, 'page_size': 20},
      auth: false));

  /// First page of the catalog, optionally filtered by artist (server side).
  Future<List<Track>> all({String? artist}) async => _parse(await _api.get(
      Endpoints.tracks,
      query: {
        'page': 1,
        'page_size': pageSize,
        if (artist != null) 'artist': artist,
      },
      auth: false));

  Future<List<Track>> search(String query, {CancelToken? cancel}) async =>
      _parse(await _api.get(Endpoints.tracks,
          query: {'q': query, 'page_size': pageSize},
          auth: false,
          cancel: cancel));
}
