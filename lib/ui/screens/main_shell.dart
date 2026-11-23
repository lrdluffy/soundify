import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundify/ui/widgets/mini_player.dart';

import '../../state/auth_controller.dart';
import 'home/home_screen.dart';
import 'library/library_screen.dart';
import 'profile/profile_screen.dart';
import 'search/search_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  bool _bannerDismissed = false;

  static const _pages = [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final sec = context.select<AuthController, bool>((a) => a.security.isSafe);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          if (!sec && !_bannerDismissed)
            MaterialBanner(
              backgroundColor: scheme.errorContainer,
              leading: Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
              content: Text(
                'این دستگاه Root شده یا شبیه‌ساز است؛ امنیت حساب شما تضمین نمی‌شود.',
                style: TextStyle(color: scheme.onErrorContainer),
              ),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _bannerDismissed = true),
                  child: const Text('متوجه شدم'),
                ),
              ],
            ),
          Expanded(child: IndexedStack(index: _index, children: _pages)),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'خانه'),
              NavigationDestination(
                  icon: Icon(Icons.search), label: 'جستجو'),
              NavigationDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music),
                  label: 'کتابخانه'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'پروفایل'),
            ],
          ),
        ],
      ),
    );
  }
}
