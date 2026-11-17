import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/util/format.dart';
import '../../../state/player_controller.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/equalizer.dart';
import '../../widgets/playlist_picker.dart';
import '../../widgets/track_tile.dart';

class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> {
  late final PlayerController _player;
  double? _dragMs; // while the user drags the seek slider

  @override
  void initState() {
    super.initState();
    _player = context.read<PlayerController>();
    // Hide the global mini player while this screen is open.
    WidgetsBinding.instance.addPostFrameCallback((_) => _player.fullScreenOpen = true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _player.fullScreenOpen = false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerController>();
    final track = player.current;
    final scheme = Theme.of(context).colorScheme;

    if (track == null) {
      return const Scaffold(body: Center(child: Text('آهنگی در حال پخش نیست')));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('در حال پخش'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'افزودن به پلی‌لیست',
            onPressed: () => showPlaylistPicker(context, track),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              Hero(
                tag: 'cover-${track.id}',
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CoverImage(url: track.coverUrl, radius: 24),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          [track.artist, if (track.album != null) track.album!].join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  FavoriteButton(track: track, size: 30),
                ],
              ),
              const SizedBox(height: 20),
              EqualizerBars(active: player.playing),
              const SizedBox(height: 8),
              _SeekBar(
                player: player,
                fallbackDuration: track.duration,
                dragMs: _dragMs,
                onDrag: (v) => setState(() => _dragMs = v),
                onDragEnd: (v) async {
                  await player.seek(Duration(milliseconds: v.round()));
                  if (mounted) setState(() => _dragMs = null);
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 44,
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: player.previous,
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: player.buffering
                        ? const Padding(
                            padding: EdgeInsets.all(22),
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : IconButton.filled(
                            iconSize: 44,
                            icon: Icon(player.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded),
                            onPressed: player.togglePlay,
                          ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    iconSize: 44,
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: player.next,
                  ),
                ],
              ),
              if (player.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(player.error!, style: TextStyle(color: scheme.error)),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeekBar extends StatelessWidget {
  const _SeekBar({
    required this.player,
    required this.fallbackDuration,
    required this.dragMs,
    required this.onDrag,
    required this.onDragEnd,
  });

  final PlayerController player;
  final Duration? fallbackDuration;
  final double? dragMs;
  final ValueChanged<double> onDrag;
  final ValueChanged<double> onDragEnd;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: player.durationStream,
      builder: (context, durSnap) {
        final duration = durSnap.data ?? fallbackDuration ?? Duration.zero;
        final totalMs = duration.inMilliseconds.toDouble();
        return StreamBuilder<Duration>(
          stream: player.positionStream,
          builder: (context, posSnap) {
            final posMs = (dragMs ?? (posSnap.data?.inMilliseconds ?? 0).toDouble())
                .clamp(0.0, totalMs > 0 ? totalMs : 1.0);
            return Column(
              children: [
                // Time labels stay left-to-right regardless of RTL layout.
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Slider(
                    value: posMs,
                    max: totalMs > 0 ? totalMs : 1.0,
                    onChanged: totalMs > 0 ? onDrag : null,
                    onChangeEnd: totalMs > 0 ? onDragEnd : null,
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatDuration(Duration(milliseconds: posMs.round()))),
                        Text(formatDuration(totalMs > 0 ? duration : null)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
