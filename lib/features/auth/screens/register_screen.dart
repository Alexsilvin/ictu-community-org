import 'package:flutter/material.dart';

import 'signup_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  @override
  Widget build(BuildContext context) {
    // Legacy screen kept only for backward compatibility.
    // Redirect immediately to the updated UI.
    return const SignupScreen();
  }
}

