import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/auth_controller.dart';
import '../../widgets/state_views.dart';

/// Shown on cold start when biometric login is enabled and a session exists.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_checking) return;
    setState(() => _checking = true);
    final ok = await context.read<AuthController>().unlock();
    if (!mounted) return;
    setState(() => _checking = false);
    if (!ok) showSnack(context, 'تأیید هویت انجام نشد');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fingerprint, size: 96, color: scheme.primary),
                const SizedBox(height: 16),
                Text('Soundify قفل است',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('برای ادامه هویت خود را تأیید کنید',
                    style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _checking ? null : _unlock,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('باز کردن قفل'),
                  style: FilledButton.styleFrom(minimumSize: const Size(220, 52)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.read<AuthController>().logout(),
                  child: const Text('ورود با حساب دیگر'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
