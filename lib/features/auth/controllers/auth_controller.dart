import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';

class AuthController {
  AuthController({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;
  final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  Future<void> signIn({required String email, required String password}) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _repository.login(email: email, password: password);
      isLoggedIn.value = true;
    } catch (e) {
      errorMessage.value = e.toString();
      isLoggedIn.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String role,
    required String faculty,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _repository.register(
        email: email,
        password: password,
        username: username,
        role: role,
        faculty: faculty,
      );
      isLoggedIn.value = true;
    } catch (e) {
      errorMessage.value = e.toString();
      isLoggedIn.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> getStoredToken() => _repository.getStoredToken();

  Future<void> logout() async {
    await _repository.logout();
    isLoggedIn.value = false;
  }

  void dispose() {
    isLoggedIn.dispose();
    isLoading.dispose();
    errorMessage.dispose();
  }
}
