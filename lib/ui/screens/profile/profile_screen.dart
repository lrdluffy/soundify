import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/auth_controller.dart';
import '../../../state/player_controller.dart';
import '../../app_state.dart';
import '../../widgets/state_views.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = context.watch<ThemeController>();
    final scheme = Theme.of(context).colorScheme;
    final user = auth.user;
    final sec = auth.security;

    return Scaffold(
      appBar: AppBar(title: const Text('پروفایل')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  (user?.displayName ?? '?').characters.first.toUpperCase(),
                  style: TextStyle(fontSize: 28, color: scheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.displayName ?? '...',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(user?.email ?? '',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _Header('امنیت'),
          Card(
            color: scheme.surfaceContainerHigh,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('ورود با اثر انگشت / چهره'),
                  subtitle: Text(auth.biometricAvailable
                      ? 'قفل برنامه هنگام اجرا'
                      : 'بیومتریک روی این دستگاه فعال نیست'),
                  value: auth.biometricEnabled,
                  onChanged: auth.biometricAvailable
                      ? (v) async {
                          final ok = await auth.setBiometric(v);
                          if (!ok && context.mounted) {
                            showSnack(context, 'تأیید هویت انجام نشد');
                          }
                        }
                      : null,
                ),
                const Divider(height: 1),
                _SecurityRow(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'دسترسی Root',
                  bad: sec.rooted,
                  badText: 'شناسایی شد',
                  goodText: 'شناسایی نشد',
                ),
                _SecurityRow(
                  icon: Icons.phone_android,
                  label: 'نوع دستگاه',
                  bad: sec.emulator,
                  badText: 'شبیه‌ساز (Emulator)',
                  goodText: 'دستگاه واقعی',
                ),
              ],
            ),
          ),
          if (!sec.isSafe)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'این دستگاه ناامن تشخیص داده شد. اطلاعات حساب شما ممکن است در معرض خطر باشد.',
                style: TextStyle(color: scheme.error, fontSize: 13),
              ),
            ),
          const SizedBox(height: 16),
          const _Header('نمایش'),
          Card(
            color: scheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode),
                      label: Text('روشن')),
                  ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode),
                      label: Text('تاریک')),
                  ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto),
                      label: Text('سیستم')),
                ],
                selected: {theme.mode},
                onSelectionChanged: (s) => theme.setMode(s.first),
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await context.read<PlayerController>().stop();
              if (context.mounted) await context.read<AuthController>().logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('خروج از حساب'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: scheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4, left: 4),
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary)),
      );
}

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({
    required this.icon,
    required this.label,
    required this.bad,
    required this.badText,
    required this.goodText,
  });

  final IconData icon;
  final String label;
  final bool bad;
  final String badText;
  final String goodText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(bad ? badText : goodText,
              style: TextStyle(color: bad ? scheme.error : scheme.primary)),
          const SizedBox(width: 6),
          Icon(bad ? Icons.warning_amber_rounded : Icons.verified_outlined,
              color: bad ? scheme.error : scheme.primary, size: 20),
        ],
      ),
    );
  }
}
