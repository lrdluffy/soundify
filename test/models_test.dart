import 'package:flutter_test/flutter_test.dart';
import 'package:soundify/data/models/playlist.dart';
import 'package:soundify/data/models/track.dart';
import 'package:soundify/core/network/api_client.dart';

void main() {
  test('Track parses flexible keys, nested artist and seconds duration', () {
    final t = Track.fromJson({
      'id': 7,
      'title': 'Song',
      'artist': {'name': 'Singer'},
      'album': 'Album',
      'cover_url': '/static/c.jpg',
      'duration': 215,
    });
    expect(t.id, '7');
    expect(t.artist, 'Singer');
    expect(t.coverUrl, startsWith('https://'));
    expect(t.duration, const Duration(seconds: 215));
    expect(t.playUrl, endsWith('/tracks/7/stream'));
  });

  test('Track treats huge duration as milliseconds and parses mm:ss', () {
    expect(Track.fromJson({'id': 1, 'title': 'a', 'duration': 215000}).duration,
        const Duration(seconds: 215));
    expect(Track.fromJson({'id': 1, 'title': 'a', 'duration': '3:35'}).duration,
        const Duration(seconds: 215));
  });

  test('Track.fromAny unwraps favorite rows', () {
    final t = Track.fromAny({
      'track': {'id': 'x', 'title': 'T', 'artist': 'A'}
    });
    expect(t.id, 'x');
  });

  test('Playlist parses embedded tracks', () {
    final p = Playlist.fromJson({
      'id': 1,
      'name': 'Mine',
      'tracks': [
        {'id': 1, 'title': 'a', 'artist': 'x'}
      ],
    });
    expect(p.count, 1);
    expect(p.tracks.single.title, 'a');
  });

  test('TokenPair parses flat and wrapped responses', () {
    expect(TokenPair.tryParse({'access_token': 'a', 'refresh_token': 'r'})?.refresh, 'r');
    expect(TokenPair.tryParse({'data': {'accessToken': 'a'}})?.access, 'a');
    expect(TokenPair.tryParse({'nothing': true}), isNull);
  });
}
