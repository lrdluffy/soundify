import 'package:flutter/material.dart';

import '../core/storage/app_prefs.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs) : mode = _prefs.themeMode;

  final AppPrefs _prefs;
  ThemeMode mode;

  Future<void> setMode(ThemeMode m) async {
    mode = m;
    notifyListeners();
    await _prefs.setThemeMode(m);
  }
}
