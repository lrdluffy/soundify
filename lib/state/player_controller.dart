import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../data/models/track.dart';

/// Wraps just_audio. Because just_audio_background is initialised in main(),
/// playback runs in a foreground media service: it survives leaving the app and
/// screen-off, and shows cover/title/artist + play/pause/next/previous in the
/// notification and on the lock screen.
class PlayerController extends ChangeNotifier {
  PlayerController() {
    _subs.add(_player.currentIndexStream.listen((i) {
      if (i != null && i >= 0 && i < queue.length) {
        current = queue[i];
        notifyListeners();
      }
    }));
    _subs.add(_player.playerStateStream.listen((s) {
      playing = s.playing && s.processingState != ProcessingState.completed;
      buffering = s.processingState == ProcessingState.loading ||
          s.processingState == ProcessingState.buffering;
      notifyListeners();
    }));
    _subs.add(_player.playbackEventStream.listen((_) {}, onError: (Object e, _) {
      error = 'پخش آهنگ با خطا مواجه شد';
      playing = false;
      buffering = false;
      notifyListeners();
    }));
  }

  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subs = [];

  List<Track> queue = [];
  Track? current;
  bool playing = false;
  bool buffering = false;
  String? error;

  bool _fullScreenOpen = false;
  bool get fullScreenOpen => _fullScreenOpen;
  set fullScreenOpen(bool v) {
    if (_fullScreenOpen == v) return;
    _fullScreenOpen = v;
    notifyListeners();
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  bool get hasTrack => current != null;

  MediaItem _item(Track t) => MediaItem(
        id: t.id,
        title: t.title,
        artist: t.artist,
        album: t.album,
        duration: t.duration,
        artUri: t.coverUrl != null ? Uri.tryParse(t.coverUrl!) : null,
      );

  Future<void> playQueue(List<Track> tracks, int index) async {
    if (tracks.isEmpty || index < 0 || index >= tracks.length) return;

    // Tapping the track that is already loaded just toggles playback.
    if (current?.id == tracks[index].id && listEquals(queue, tracks)) {
      await togglePlay();
      return;
    }

    queue = List<Track>.of(tracks);
    current = queue[index];
    error = null;
    buffering = true;
    notifyListeners();

    try {
      final source = ConcatenatingAudioSource(children: [
        for (final t in queue) AudioSource.uri(Uri.parse(t.playUrl), tag: _item(t)),
      ]);
      await _player.setAudioSource(source,
          initialIndex: index, initialPosition: Duration.zero);
      unawaited(_player.play());
    } catch (e) {
      error = 'پخش آهنگ ممکن نیست';
      playing = false;
      buffering = false;
      notifyListeners();
    }
  }

  Future<void> togglePlay() async {
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero, index: 0);
      unawaited(_player.play());
      return;
    }
    if (_player.playing) {
      await _player.pause();
    } else {
      unawaited(_player.play());
    }
  }

  Future<void> next() => _player.seekToNext();
  Future<void> previous() async {
    // Standard behaviour: restart the track if already past 3 seconds.
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
    } else {
      await _player.seekToPrevious();
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> stop() async {
    await _player.stop();
    queue = [];
    current = null;
    playing = false;
    buffering = false;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}
