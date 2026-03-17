import 'package:flutter/material.dart';

import '../../navigation/screens/main_shell.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  // Simple defaults; you can replace with dropdowns sourced from your constants.
  String _role = 'student';
  String _faculty = 'ICTU';

  final AuthController _authController = AuthController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _authController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    await _authController.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      username: _usernameController.text.trim(),
      role: _role,
      faculty: _faculty,
    );

    if (!mounted || !_authController.isLoggedIn.value) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'University email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'student', child: Text('Student')),
                DropdownMenuItem(value: 'delegate', child: Text('Delegate')),
                DropdownMenuItem(value: 'lecturer', child: Text('Lecturer')),
              ],
              onChanged: (v) => setState(() => _role = v ?? _role),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Faculty'),
              onChanged: (v) => _faculty = v.trim(),
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<bool>(
              valueListenable: _authController.isLoading,
              builder: (context, loading, _) {
                return ElevatedButton(
                  onPressed: loading ? null : _onRegister,
                  child: Text(loading ? 'Creating...' : 'Register'),
                );
              },
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<String?>(
              valueListenable: _authController.errorMessage,
              builder: (context, err, _) {
                if (err == null) return const SizedBox.shrink();
                return Text(err, style: const TextStyle(color: Colors.red));
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}

