import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/security/biometric_service.dart';
import 'core/storage/app_prefs.dart';
import 'core/storage/token_storage.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/favorites_repository.dart';
import 'data/repositories/playlist_repository.dart';
import 'data/repositories/track_repository.dart';
import 'state/auth_controller.dart';
import 'state/catalog_controller.dart';
import 'state/library_controller.dart';
import 'state/player_controller.dart';
import 'ui/app_state.dart';
import 'ui/screens/auth/lock_screen.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/main_shell.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/mini_player.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class SoundifyApp extends StatelessWidget {
  const SoundifyApp({super.key, required this.prefs});

  final AppPrefs prefs;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppPrefs>.value(value: prefs),
        Provider<TokenStorage>(create: (_) => TokenStorage()),
        ProxyProvider<TokenStorage, ApiClient>(
          update: (_, tokens, prev) => prev ?? ApiClient(tokens: tokens),
        ),
        ProxyProvider2<ApiClient, TokenStorage, AuthRepository>(
          update: (_, api, tokens, __) => AuthRepository(api, tokens),
        ),
        ProxyProvider<ApiClient, TrackRepository>(
            update: (_, api, __) => TrackRepository(api)),
        ProxyProvider<ApiClient, PlaylistRepository>(
            update: (_, api, __) => PlaylistRepository(api)),
        ProxyProvider<ApiClient, FavoritesRepository>(
            update: (_, api, __) => FavoritesRepository(api)),
        ChangeNotifierProvider(create: (_) => ThemeController(prefs)),
        ChangeNotifierProvider(
          create: (c) => AuthController(
            repo: c.read<AuthRepository>(),
            prefs: prefs,
            api: c.read<ApiClient>(),
            biometrics: BiometricService(),
          )..bootstrap(),
        ),
        ChangeNotifierProvider(
            create: (c) => CatalogController(c.read<TrackRepository>())),
        ChangeNotifierProvider(
          create: (c) => LibraryController(
              c.read<PlaylistRepository>(), c.read<FavoritesRepository>()),
        ),
        ChangeNotifierProvider(create: (_) => PlayerController()),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<ThemeController, ThemeMode>((t) => t.mode);
    return MaterialApp(
      title: 'Soundify',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      // Persian, right-to-left.
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        final auth = context.watch<AuthController>();
        final player = context.watch<PlayerController>();
        final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
        final showMini = auth.status == AuthStatus.authenticated &&
            player.hasTrack &&
            !player.fullScreenOpen &&
            !keyboardOpen;
        // Keep the same widget types in both states so the Navigator is never
        // re-mounted when the mini player appears/disappears.
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeBottom: showMini,
                  child: child!,
                ),
              ),
              if (showMini)
                SafeArea(
                  top: false,
                  child: MiniPlayer(navigatorKey: rootNavigatorKey),
                ),
            ],
          ),
        );
      },
      home: const _AuthGate(),
    );
  }
}

/// Chooses the root screen from the auth state and keeps per-session data in
/// sync (load on login, clear on logout).
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  AuthStatus? _last;

  void _onStatusChanged(AuthStatus status) {
    if (status == _last) return;
    final wasAuthed = _last == AuthStatus.authenticated;
    _last = status;
    final catalog = context.read<CatalogController>();
    final library = context.read<LibraryController>();
    final player = context.read<PlayerController>();

    if (status == AuthStatus.authenticated) {
      catalog.load();
      library.loadAll();
    } else if (wasAuthed) {
      catalog.clear();
      library.clear();
      player.stop();
      // Drop any screens (full player, auth pages) stacked above the gate.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        rootNavigatorKey.currentState?.popUntil((r) => r.isFirst);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthController, AuthStatus>((a) => a.status);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onStatusChanged(status);
    });

    switch (status) {
      case AuthStatus.initializing:
        return const SplashScreen();
      case AuthStatus.onboarding:
        return const OnboardingScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.locked:
        return const LockScreen();
      case AuthStatus.authenticated:
        return const MainShell();
    }
  }
}
