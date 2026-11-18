import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/security/biometric_service.dart';
import '../core/security/device_security.dart';
import '../core/storage/app_prefs.dart';
import '../data/models/user.dart';
import '../data/repositories/auth_repository.dart';

enum AuthStatus { initializing, onboarding, unauthenticated, locked, authenticated }

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository repo,
    required AppPrefs prefs,
    required ApiClient api,
    required BiometricService biometrics,
  })  : _repo = repo,
        _prefs = prefs,
        _biometrics = biometrics {
    api.onSessionExpired = _onSessionExpired;
  }

  final AuthRepository _repo;
  final AppPrefs _prefs;
  final BiometricService _biometrics;

  AuthStatus status = AuthStatus.initializing;
  User? user;
  DeviceSecurityReport security = DeviceSecurityReport.unknown;
  bool biometricAvailable = false;

  bool get biometricEnabled => _prefs.biometricEnabled;

  Future<void> bootstrap() async {
    final minSplash = Future<void>.delayed(const Duration(milliseconds: 1400));
    biometricAvailable = await _biometrics.isAvailable();
    security = await DeviceSecurity.check();
    final hasSession = await _repo.hasSession();
    await minSplash;

    if (!_prefs.onboardingSeen) {
      status = AuthStatus.onboarding;
    } else if (!hasSession) {
      status = AuthStatus.unauthenticated;
    } else if (_prefs.biometricEnabled && biometricAvailable) {
      status = AuthStatus.locked;
    } else {
      status = AuthStatus.authenticated;
      _loadUser();
    }
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await _prefs.setOnboardingSeen();
    status = (await _repo.hasSession())
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ---- credentials flows (throw ApiException; screens show the message) ----

  Future<void> login(String email, String password) async {
    await _repo.login(email, password);
    await _enter();
  }

  /// Creates the (unverified) account. The server emails an OTP; the caller
  /// then shows the verification screen. No session is created here.
  Future<void> register(
          String email, String username, String password, String? displayName) =>
      _repo.register(
          email: email,
          username: username,
          password: password,
          displayName: displayName);

  Future<void> requestOtp(String email) => _repo.requestOtp(email);

  /// Verifies the account (no tokens are issued; log in afterwards).
  Future<void> verifyOtp(String email, String code) =>
      _repo.verifyOtp(email, code);

  Future<void> requestPasswordReset(String email) =>
      _repo.requestPasswordReset(email);

  Future<void> confirmPasswordReset(
          String email, String code, String newPassword) =>
      _repo.confirmPasswordReset(
          email: email, code: code, newPassword: newPassword);

  Future<void> _enter() async {
    status = AuthStatus.authenticated;
    notifyListeners();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      user = await _repo.me();
      notifyListeners();
    } catch (_) {
      // Profile is non-critical; the session itself is still valid.
    }
  }

  // ---- biometrics ----

  Future<bool> unlock() async {
    final ok = await _biometrics.authenticate('برای ورود به Soundify هویت خود را تأیید کنید');
    if (ok) {
      status = AuthStatus.authenticated;
      notifyListeners();
      _loadUser();
    }
    return ok;
  }

  /// Returns true if the setting was changed.
  Future<bool> setBiometric(bool enable) async {
    if (enable) {
      if (!await _biometrics.isAvailable()) return false;
      final ok = await _biometrics.authenticate('برای فعال‌سازی ورود بیومتریک تأیید کنید');
      if (!ok) return false;
    }
    await _prefs.setBiometricEnabled(enable);
    notifyListeners();
    return true;
  }

  // ---- session end ----

  Future<void> logout() async {
    await _repo.logout();
    await _prefs.setBiometricEnabled(false);
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Refresh token rejected by the server: tokens are already cleared.
  Future<void> _onSessionExpired() async {
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
