import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive flags only (onboarding, theme, biometric opt-in).
/// Tokens are NOT stored here - see TokenStorage.
class AppPrefs {
  AppPrefs._(this._p);

  final SharedPreferences _p;

  static const _kOnboarding = 'onboarding_seen';
  static const _kBiometric = 'biometric_enabled';
  static const _kTheme = 'theme_mode';

  static Future<AppPrefs> load() async =>
      AppPrefs._(await SharedPreferences.getInstance());

  bool get onboardingSeen => _p.getBool(_kOnboarding) ?? false;
  Future<void> setOnboardingSeen() => _p.setBool(_kOnboarding, true);

  bool get biometricEnabled => _p.getBool(_kBiometric) ?? false;
  Future<void> setBiometricEnabled(bool v) => _p.setBool(_kBiometric, v);

  ThemeMode get themeMode {
    switch (_p.getString(_kTheme)) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode m) => _p.setString(_kTheme, m.name);
}
