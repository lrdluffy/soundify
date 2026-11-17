import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/util/debouncer.dart';
import '../../../data/models/track.dart';
import '../../../data/repositories/track_repository.dart';
import '../../../state/library_controller.dart';
import '../../widgets/state_views.dart';
import '../../widgets/track_tile.dart';

/// Live search with debounce; in-flight requests are cancelled when the query
/// changes so stale results can never overwrite newer ones.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _debouncer = Debouncer(AppConfig.searchDebounce);
  CancelToken? _cancel;

  LoadState _state = LoadState.idle;
  String _query = '';
  String? _error;
  List<Track> _results = const [];

  @override
  void dispose() {
    _debouncer.cancel();
    _cancel?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final q = value.trim();
    _debouncer.run(() => _search(q));
    setState(() {}); // refresh the clear button
  }

  Future<void> _search(String q) async {
    _cancel?.cancel();
    if (q.isEmpty) {
      setState(() {
        _query = '';
        _state = LoadState.idle;
        _results = const [];
      });
      return;
    }
    final token = CancelToken();
    _cancel = token;
    setState(() {
      _query = q;
      _state = LoadState.loading;
    });
    try {
      final res =
          await context.read<TrackRepository>().search(q, cancel: token);
      if (!mounted || token.isCancelled) return;
      setState(() {
        _results = res;
        _state = LoadState.ready;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException && e.type == ApiErrorType.cancelled) return;
      setState(() {
        _error = errorText(e);
        _state = LoadState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جستجو'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) {
                _debouncer.cancel();
                _search(v.trim());
              },
              decoration: InputDecoration(
                hintText: 'نام آهنگ یا خواننده...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          _debouncer.cancel();
                          _search('');
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
      body: _state == LoadState.idle
          ? const EmptyView(
              message: 'برای یافتن آهنگ، نام اثر یا خواننده را جستجو کنید',
              icon: Icons.search,
            )
          : StateView(
              state: _state,
              isEmpty: _results.isEmpty,
              emptyMessage: 'نتیجه‌ای برای «$_query» پیدا نشد',
              emptyIcon: Icons.search_off,
              error: _error,
              onRetry: () => _search(_query),
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (_, i) =>
                    TrackTile(track: _results[i], queue: _results, index: i),
              ),
            ),
    );
  }
}
