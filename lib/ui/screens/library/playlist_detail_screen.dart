import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundify/ui/widgets/mini_player.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/playlist.dart';
import '../../../data/models/track.dart';
import '../../../state/library_controller.dart';
import '../../../state/player_controller.dart';
import '../../widgets/state_views.dart';
import '../../widgets/track_tile.dart';

class PlaylistDetailScreen extends StatefulWidget {
  const PlaylistDetailScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  LoadState _state = LoadState.loading;
  String? _error;
  List<Track> _tracks = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Playlist? _find(LibraryController lib) {
    for (final p in lib.playlists) {
      if (p.id == widget.playlistId) return p;
    }
    return null;
  }

  Future<void> _load() async {
    final lib = context.read<LibraryController>();
    final playlist = _find(lib);
    if (playlist == null) {
      if (mounted) setState(() => _state = LoadState.ready);
      return;
    }
    setState(() => _state = LoadState.loading);
    try {
      final tracks = await lib.tracksOf(playlist);
      if (!mounted) return;
      setState(() {
        _tracks = tracks;
        _state = LoadState.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = errorText(e);
        _state = LoadState.error;
      });
    }
  }

  Future<void> _remove(Track t) async {
    final lib = context.read<LibraryController>();
    try {
      await lib.removeFromPlaylist(widget.playlistId, t.id);
      if (mounted) setState(() => _tracks = _tracks.where((x) => x.id != t.id).toList());
    } catch (e) {
      if (mounted) showSnack(context, errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryController>();
    final playlist = _find(lib);

    return Scaffold(
      appBar: AppBar(title: Text(playlist?.name ?? 'پلی‌لیست')),
      floatingActionButton: _tracks.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  context.read<PlayerController>().playQueue(_tracks, 0),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('پخش همه'),
            ),
      body: StateView(
        state: _state,
        isEmpty: _tracks.isEmpty,
        emptyMessage: 'این پلی‌لیست خالی است.\nاز صفحه خانه آهنگ اضافه کنید.',
        emptyIcon: Icons.queue_music,
        error: _error,
        onRetry: _load,
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: _tracks.length,
          itemBuilder: (context, i) => TrackTile(
            track: _tracks[i],
            queue: _tracks,
            index: i,
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: 'حذف از پلی‌لیست',
              onPressed: () => _remove(_tracks[i]),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const MiniPlayer(safeBottom: true,),
    );
  }
}
