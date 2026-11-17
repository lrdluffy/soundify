import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../data/models/track.dart';
import '../../state/library_controller.dart';
import 'state_views.dart';

/// Bottom sheet: pick a playlist to add [track] to (or create a new one).
Future<void> showPlaylistPicker(BuildContext context, Track track) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _PlaylistPicker(track: track),
  );
}

class _PlaylistPicker extends StatelessWidget {
  const _PlaylistPicker({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryController>();
    return SafeArea(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('افزودن به پلی‌لیست',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('پلی‌لیست جدید'),
              onTap: () async {
                final nav = Navigator.of(context);
                final input = await showPlaylistDialog(context);
                if (input != null && context.mounted) {
                  try {
                    final before = lib.playlists.map((p) => p.id).toSet();
                    await lib.createPlaylist(input.name, input.description);
                    // The new playlist is whichever id was not there before.
                    final fresh =
                        lib.playlists.where((p) => !before.contains(p.id));
                    if (fresh.isNotEmpty) {
                      await lib.addToPlaylist(fresh.first.id, track);
                    }
                    nav.pop();
                  } catch (e) {
                    if (context.mounted) showSnack(context, errorText(e));
                  }
                }
              },
            ),
            const Divider(height: 1),
            Flexible(
              child: StateView(
                state: lib.playlistsState,
                isEmpty: lib.playlists.isEmpty,
                emptyMessage: 'هنوز پلی‌لیستی ندارید',
                emptyIcon: Icons.queue_music,
                error: lib.playlistsError,
                onRetry: lib.loadPlaylists,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: lib.playlists.length,
                  itemBuilder: (context, i) {
                    final p = lib.playlists[i];
                    return ListTile(
                      leading: const Icon(Icons.queue_music),
                      title: Text(p.name),
                      subtitle: Text('${p.count} آهنگ'),
                      onTap: () async {
                        final nav = Navigator.of(context);
                        try {
                          await lib.addToPlaylist(p.id, track);
                          nav.pop();
                          if (context.mounted) {
                            showSnack(context, 'به «${p.name}» اضافه شد');
                          }
                        } catch (e) {
                          if (context.mounted) showSnack(context, errorText(e));
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaylistInput {
  const PlaylistInput(this.name, this.description);
  final String name;
  final String? description;
}

/// Create / edit dialog. Pass [initialName]/[initialDescription] to edit.
Future<PlaylistInput?> showPlaylistDialog(
  BuildContext context, {
  String? initialName,
  String? initialDescription,
}) {
  final name = TextEditingController(text: initialName);
  final desc = TextEditingController(text: initialDescription);
  final key = GlobalKey<FormState>();
  final editing = initialName != null;

  return showDialog<PlaylistInput>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(editing ? 'ویرایش پلی‌لیست' : 'پلی‌لیست جدید'),
      content: Form(
        key: key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'نام پلی‌لیست'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'نام پلی‌لیست را وارد کنید' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: desc,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'توضیحات (اختیاری)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () {
            if (key.currentState!.validate()) {
              Navigator.pop(ctx, PlaylistInput(name.text.trim(), desc.text.trim()));
            }
          },
          child: Text(editing ? 'ذخیره' : 'ایجاد'),
        ),
      ],
    ),
  );
}
