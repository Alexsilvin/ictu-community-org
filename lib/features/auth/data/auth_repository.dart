import 'auth_api.dart';
import 'auth_storage.dart';

typedef JsonMap = Map<String, dynamic>;

class AuthRepository {
  AuthRepository({AuthApi? api, AuthStorage? storage})
      : _api = api ?? AuthApi(),
        _storage = storage ?? AuthStorage();

  final AuthApi _api;
  final AuthStorage _storage;

  Future<JsonMap> login({required String email, required String password}) async {
    final data = await _api.login(email: email, password: password);
    final token = data['access_token'] as String?;
    if (token != null && token.isNotEmpty) {
      await _storage.saveAccessToken(token);
    }
    return data;
  }

  Future<JsonMap> register({
    required String email,
    required String password,
    required String username,
    required String role,
    required String faculty,
  }) async {
    final data = await _api.register(
      email: email,
      password: password,
      username: username,
      role: role,
      faculty: faculty,
    );

    final token = data['access_token'] as String?;
    if (token != null && token.isNotEmpty) {
      await _storage.saveAccessToken(token);
    }
    return data;
  }

  Future<String?> getStoredToken() => _storage.readAccessToken();

  Future<void> logout() => _storage.clear();
}

