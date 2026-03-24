import 'auth_api.dart';
import 'auth_storage.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

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

    // IMPORTANT: The edge function login does not automatically create a
    // Supabase Auth session on the client. Storage + RLS require an authenticated
    // supabase_flutter session (JWT attached to requests).
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

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

    // Establish an authenticated session for subsequent Storage/DB calls.
    // If the user already exists, signUp may fail; we fall back to signIn.
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
    } catch (_) {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    }

    return data;
  }

  Future<String?> getStoredToken() => _storage.readAccessToken();

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    await _storage.clear();
  }
}

