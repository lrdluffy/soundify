import '../../core/network/api_client.dart';
import '../../core/network/api_contract.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../models/json_utils.dart';
import '../models/user.dart';

class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStorage _tokens;

  /// Creates an UNVERIFIED account; the server emails a 6-digit OTP.
  /// No tokens are returned - the user must verify, then log in.
  Future<void> register({
    required String email,
    required String username,
    required String password,
    String? displayName,
  }) =>
      _api.post(Endpoints.register, auth: false, data: {
        Keys.email: email.trim(),
        Keys.username: username.trim(),
        Keys.password: password,
        if (displayName != null && displayName.trim().isNotEmpty)
          Keys.displayName: displayName.trim(),
      });

  Future<void> login(String email, String password) async {
    final body = await _api.post(
      Endpoints.login,
      auth: false,
      data: {Keys.email: email.trim(), Keys.password: password},
    );
    final pair = TokenPair.tryParse(body);
    if (pair == null) {
      throw const ApiException(ApiErrorType.unknown, 'پاسخ سرور شامل توکن نبود');
    }
    await _tokens.save(access: pair.access, refresh: pair.refresh);
  }

  /// (Re)sends the email-verification OTP. Rate limit: once per 60 s.
  Future<void> requestOtp(String email) => _api.post(Endpoints.otpRequest,
      auth: false, data: {Keys.email: email.trim()});

  /// Marks the account verified. Does NOT return tokens.
  Future<void> verifyOtp(String email, String code) => _api.post(
      Endpoints.otpVerify,
      auth: false,
      data: {Keys.email: email.trim(), Keys.code: code.trim()});

  Future<void> requestPasswordReset(String email) => _api.post(
      Endpoints.resetRequest,
      auth: false,
      data: {Keys.email: email.trim()});

  Future<void> confirmPasswordReset(
          {required String email,
          required String code,
          required String newPassword}) =>
      _api.post(Endpoints.resetConfirm, auth: false, data: {
        Keys.email: email.trim(),
        Keys.code: code.trim(),
        Keys.newPassword: newPassword,
      });

  Future<User> me() async => User.fromJson(asMap(await _api.get(Endpoints.me)));

  Future<bool> hasSession() => _tokens.hasSession;

  /// Revokes the tokens on the server (best effort), then always clears them locally.
  Future<void> logout() async {
    try {
      final refresh = await _tokens.refreshToken;
      await _api.post(Endpoints.logout,
          data: {if (refresh != null) Keys.refreshToken: refresh});
    } catch (_) {
      // Offline / expired: local sign-out must still succeed.
    } finally {
      await _tokens.clear();
    }
  }
}
