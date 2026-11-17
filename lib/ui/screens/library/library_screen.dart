import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/playlist.dart';
import '../../../state/library_controller.dart';
import '../../widgets/playlist_picker.dart';
import '../../widgets/state_views.dart';
import '../../widgets/track_tile.dart';
import 'playlist_detail_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('کتابخانه'),
          bottom: const TabBar(tabs: [
            Tab(text: 'پلی‌لیست‌ها'),
            Tab(text: 'علاقه‌مندی‌ها'),
          ]),
        ),
        body: const TabBarView(children: [_PlaylistsTab(), _FavoritesTab()]),
      ),
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab();

  Future<void> _create(BuildContext context) async {
    final lib = context.read<LibraryController>();
    final input = await showPlaylistDialog(context);
    if (input == null) return;
    try {
      await lib.createPlaylist(input.name, input.description);
    } catch (e) {
      if (context.mounted) showSnack(context, errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryController>();
    return Stack(
      children: [
        StateView(
          state: lib.playlistsState,
          isEmpty: lib.playlists.isEmpty,
          emptyMessage: 'هنوز پلی‌لیستی نساخته‌اید',
          emptyIcon: Icons.queue_music,
          emptyAction: FilledButton.icon(
            onPressed: () => _create(context),
            icon: const Icon(Icons.add),
            label: const Text('ساخت پلی‌لیست'),
            style: FilledButton.styleFrom(minimumSize: const Size(180, 46)),
          ),
          error: lib.playlistsError,
          onRetry: lib.loadPlaylists,
          child: RefreshIndicator(
            onRefresh: lib.loadPlaylists,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: lib.playlists.length,
              itemBuilder: (context, i) => _PlaylistTile(playlist: lib.playlists[i]),
            ),
          ),
        ),
        if (lib.playlists.isNotEmpty)
          PositionedDirectional(
            end: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () => _create(context),
              tooltip: 'پلی‌لیست جدید',
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final lib = context.read<LibraryController>();
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.queue_music, color: scheme.onPrimaryContainer),
      ),
      title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          '${playlist.count} آهنگ',
          if (playlist.description != null && playlist.description!.isNotEmpty)
            playlist.description!,
        ].join(' • '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => PlaylistDetailScreen(playlistId: playlist.id))),
      trailing: PopupMenuButton<String>(
        onSelected: (v) async {
          if (v == 'edit') {
            final input = await showPlaylistDialog(context,
                initialName: playlist.name,
                initialDescription: playlist.description);
            if (input == null) return;
            try {
              await lib.updatePlaylist(playlist.id, input.name, input.description);
            } catch (e) {
              if (context.mounted) showSnack(context, errorText(e));
            }
          } else if (v == 'delete') {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('حذف پلی‌لیست'),
                content: Text('«${playlist.name}» حذف شود؟'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('انصراف')),
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('حذف'),
                  ),
                ],
              ),
            );
            if (ok != true) return;
            try {
              await lib.deletePlaylist(playlist.id);
            } catch (e) {
              if (context.mounted) showSnack(context, errorText(e));
            }
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('ویرایش')),
          PopupMenuItem(value: 'delete', child: Text('حذف')),
        ],
      ),
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryController>();
    return StateView(
      state: lib.favoritesState,
      isEmpty: lib.favorites.isEmpty,
      emptyMessage: 'آهنگی را لایک نکرده‌اید',
      emptyIcon: Icons.favorite_border,
      error: lib.favoritesError,
      onRetry: lib.loadFavorites,
      child: RefreshIndicator(
        onRefresh: lib.loadFavorites,
        child: ListView.builder(
          itemCount: lib.favorites.length,
          itemBuilder: (_, i) =>
              TrackTile(track: lib.favorites[i], queue: lib.favorites, index: i),
        ),
      ),
    );
  }
}
