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

  Future<void> register(
      {required String email, required String password, String? name}) async {
    final body = await _api.post(
      Endpoints.register,
      auth: false,
      data: {
        Keys.email: email.trim(),
        Keys.password: password,
        if (name != null && name.trim().isNotEmpty) Keys.name: name.trim(),
      },
    );
    // Some servers return tokens on registration; keep them if so.
    await _saveIfTokens(body, required: false);
  }

  Future<void> login(String email, String password) async {
    final body = await _api.post(
      Endpoints.login,
      auth: false,
      data: {Keys.email: email.trim(), Keys.password: password},
    );
    await _saveIfTokens(body);
  }

  Future<void> requestOtp(String email) => _api.post(Endpoints.otpRequest,
      auth: false, data: {Keys.email: email.trim()});

  Future<void> verifyOtp(String email, String code) async {
    final body = await _api.post(
      Endpoints.otpVerify,
      auth: false,
      data: {Keys.email: email.trim(), Keys.code: code.trim()},
    );
    await _saveIfTokens(body);
  }

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

  Future<void> logout() => _tokens.clear();

  Future<void> _saveIfTokens(dynamic body, {bool required = true}) async {
    final pair = TokenPair.tryParse(body);
    if (pair == null) {
      if (required) {
        throw const ApiException(
            ApiErrorType.unknown, 'پاسخ سرور شامل توکن نبود');
      }
      return;
    }
    await _tokens.save(access: pair.access, refresh: pair.refresh);
  }
}
