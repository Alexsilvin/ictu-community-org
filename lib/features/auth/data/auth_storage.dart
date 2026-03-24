import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  AuthStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String accessTokenKey = 'access_token';

  Future<void> saveAccessToken(String token) {
    return _storage.write(key: accessTokenKey, value: token);
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: accessTokenKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: accessTokenKey);
  }
}

