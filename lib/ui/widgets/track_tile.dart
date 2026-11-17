import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/util/format.dart';
import '../../data/models/track.dart';
import '../../state/library_controller.dart';
import '../../state/player_controller.dart';
import 'cover_image.dart';
import 'playlist_picker.dart';
import 'state_views.dart';

class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.track,
    required this.queue,
    required this.index,
    this.trailing,
  });

  final Track track;
  final List<Track> queue;
  final int index;

  /// Replaces the default like + menu actions (e.g. a "remove" button).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerController>();
    final isCurrent = player.current?.id == track.id;
    final scheme = Theme.of(context).colorScheme;

    final subtitle = [track.artist, if (track.album != null) track.album!].join(' • ');

    return ListTile(
      onTap: () => player.playQueue(queue, index),
      leading: Stack(
        alignment: Alignment.center,
        children: [
          CoverImage(url: track.coverUrl, size: 52),
          if (isCurrent)
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                player.playing ? Icons.graphic_eq_rounded : Icons.pause_rounded,
                color: scheme.primary,
              ),
            ),
        ],
      ),
      title: Text(track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontWeight: FontWeight.w600, color: isCurrent ? scheme.primary : null)),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(formatDuration(track.duration),
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
              FavoriteButton(track: track),
              IconButton(
                icon: const Icon(Icons.playlist_add),
                tooltip: 'افزودن به پلی‌لیست',
                onPressed: () => showPlaylistPicker(context, track),
              ),
            ],
          ),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.track, this.size = 24});

  final Track track;
  final double size;

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryController>();
    final fav = lib.isFavorite(track.id);
    return IconButton(
      iconSize: size,
      tooltip: fav ? 'حذف از علاقه‌مندی‌ها' : 'افزودن به علاقه‌مندی‌ها',
      icon: Icon(fav ? Icons.favorite : Icons.favorite_border,
          color: fav ? Colors.redAccent : null),
      onPressed: () async {
        try {
          await lib.toggleFavorite(track);
        } catch (e) {
          if (context.mounted) showSnack(context, errorText(e));
        }
      },
    );
  }
}
