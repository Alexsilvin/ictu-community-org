import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_instance.dart';

typedef JsonMap = Map<String, dynamic>;

class AuthApi {
  AuthApi({SupabaseClient? client}) : _client = client ?? SupabaseInstance.client;

  final SupabaseClient _client;

  Future<JsonMap> register({
    required String email,
    required String password,
    required String username,
    required String role,
    required String faculty,
  }) async {
    final res = await _client.functions.invoke(
      'register',
      body: {
        'email': email,
        'password': password,
        'username': username,
        'role': role,
        'faculty': faculty,
      },
    );

    if (res.status != 200) {
      throw AuthException(_extractError(res.data) ?? 'Registration failed');
    }

    return _asJsonMap(res.data);
  }

  Future<JsonMap> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.functions.invoke(
      'login',
      body: {
        'email': email,
        'password': password,
      },
    );

    if (res.status != 200) {
      throw AuthException(_extractError(res.data) ?? 'Login failed');
    }

    return _asJsonMap(res.data);
  }

  JsonMap _asJsonMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is String) {
      return jsonDecode(data) as JsonMap;
    }
    throw const FormatException('Unexpected response from server');
  }

  String? _extractError(dynamic data) {
    try {
      final map = _asJsonMap(data);
      final err = map['error'];
      return err is String ? err : err?.toString();
    } catch (_) {
      return null;
    }
  }
}

