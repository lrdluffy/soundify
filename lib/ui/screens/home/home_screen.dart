import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/track.dart';
import '../../../state/catalog_controller.dart';
import '../../../state/player_controller.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/state_views.dart';
import '../../widgets/track_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Soundify')),
      body: StateView(
        state: catalog.state,
        isEmpty: catalog.all.isEmpty && catalog.featured.isEmpty,
        emptyMessage: 'هنوز آهنگی موجود نیست',
        error: catalog.error,
        onRetry: catalog.load,
        child: RefreshIndicator(
          onRefresh: catalog.load,
          child: CustomScrollView(
            slivers: [
              if (catalog.featured.isNotEmpty) ...[
                const _SectionTitle('منتخب‌ها'),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 210,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: catalog.featured.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) =>
                          _FeaturedCard(tracks: catalog.featured, index: i),
                    ),
                  ),
                ),
              ],
              const _SectionTitle('دسته‌بندی'),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: catalog.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final c = catalog.categories[i];
                      return ChoiceChip(
                        label: Text(c),
                        selected: catalog.selectedCategory == c,
                        onSelected: (_) => catalog.selectCategory(c),
                      );
                    },
                  ),
                ),
              ),
              const _SectionTitle('همه آهنگ‌ها'),
              SliverList.builder(
                itemCount: catalog.filtered.length,
                itemBuilder: (context, i) => TrackTile(
                  track: catalog.filtered[i],
                  queue: catalog.filtered,
                  index: i,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
      );
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.tracks, required this.index});

  final List<Track> tracks;
  final int index;

  @override
  Widget build(BuildContext context) {
    final track = tracks[index];
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => context.read<PlayerController>().playQueue(tracks, index),
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoverImage(url: track.coverUrl, size: 150, radius: 16),
            const SizedBox(height: 8),
            Text(track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
