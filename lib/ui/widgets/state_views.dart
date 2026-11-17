import 'package:flutter/material.dart';

import '../../state/library_controller.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.library_music_outlined,
    this.action,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: color, fontSize: 15)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: scheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
              style: FilledButton.styleFrom(minimumSize: const Size(160, 44)),
            ),
          ],
        ),
      ),
    );
  }
}

/// One place that maps loading / empty / error / content, used by every list.
class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.state,
    required this.isEmpty,
    required this.emptyMessage,
    required this.onRetry,
    required this.child,
    this.error,
    this.emptyIcon = Icons.library_music_outlined,
    this.emptyAction,
  });

  final LoadState state;
  final bool isEmpty;
  final String emptyMessage;
  final String? error;
  final IconData emptyIcon;
  final Widget? emptyAction;
  final VoidCallback onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case LoadState.idle:
      case LoadState.loading:
        return const LoadingView();
      case LoadState.error:
        return ErrorView(message: error ?? 'خطا در دریافت اطلاعات', onRetry: onRetry);
      case LoadState.ready:
        return isEmpty
            ? EmptyView(message: emptyMessage, icon: emptyIcon, action: emptyAction)
            : child;
    }
  }
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}
