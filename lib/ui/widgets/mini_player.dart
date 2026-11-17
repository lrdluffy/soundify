import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/player_controller.dart';
import '../screens/player/full_player_screen.dart';
import 'cover_image.dart';

/// Pinned above the bottom of every screen while a track is loaded.
/// Built in MaterialApp.builder, so it needs the root navigator key.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerController>();
    final track = player.current;
    if (track == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHigh,
      elevation: 6,
      child: InkWell(
        onTap: () => navigatorKey.currentState?.push(
          PageRouteBuilder<void>(
            fullscreenDialog: true,
            transitionsBuilder: (_, a, __, child) => SlideTransition(
              position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
              child: child,
            ),
            pageBuilder: (_, __, ___) => const FullPlayerScreen(),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (_, snap) {
                final total = track.duration?.inMilliseconds ?? 0;
                final pos = snap.data?.inMilliseconds ?? 0;
                return LinearProgressIndicator(
                  minHeight: 2,
                  value: total > 0 ? (pos / total).clamp(0.0, 1.0).toDouble() : null,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  CoverImage(url: track.coverUrl, size: 44, radius: 8),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(player.error ?? track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                color: player.error != null
                                    ? scheme.error
                                    : scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: player.previous,
                  ),
                  player.buffering
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5)),
                        )
                      : IconButton(
                          iconSize: 34,
                          icon: Icon(player.playing
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded),
                          onPressed: player.togglePlay,
                        ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: player.next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
