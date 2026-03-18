import 'package:flutter/material.dart';

import '../../navigation/screens/main_shell.dart';
import '../controllers/auth_controller.dart';
import '../utils/auth_validation.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthController _authController = AuthController();

  // Backend-required fields (see Supabase `register` function).
  // Keeping simple defaults for now; can be upgraded to dropdown inputs later.
  String _role = 'student';
  String _faculty = 'ICTU';

  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _authController.dispose();
    super.dispose();
  }

  Future<void> _onSignup() async {
    setState(() {
      _errorText = null;
    });

    final nameErr = AuthValidation.validateFullName(_nameController.text);
    if (nameErr != null) {
      setState(() => _errorText = nameErr);
      return;
    }

    final emailErr = AuthValidation.validateIctuEmail(_emailController.text);
    if (emailErr != null) {
      setState(() => _errorText = emailErr);
      return;
    }

    final passErr = AuthValidation.validateStrongPassword(_passwordController.text);
    if (passErr != null) {
      setState(() => _errorText = passErr);
      return;
    }

    final confirmErr = AuthValidation.validateConfirmPassword(
      _passwordController.text,
      _confirmPasswordController.text,
    );
    if (confirmErr != null) {
      setState(() => _errorText = confirmErr);
      return;
    }

    await _authController.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      username: _nameController.text.trim(),
      role: _role,
      faculty: _faculty,
    );

    // Surface backend error (if any) in the existing inline error area.
    final String? authError = _authController.errorMessage.value;
    if (authError != null) {
      setState(() {
        _errorText = authError;
      });
    }

    if (!mounted || !_authController.isLoggedIn.value) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double sx = constraints.maxWidth / 425;
          final double sy = constraints.maxHeight / 884;

          return Stack(
            children: [
              Container(color: isDark ? const Color(0xFF000205) : Colors.white),
              Positioned(
                left: 272 * sx,
                top: 695 * sy,
                width: 193 * sx,
                height: 175 * sy,
                child: _CircleDecor(
                  color: isDark
                      ? const Color(0xFF600063).withValues(alpha: 0.43)
                      : const Color(0xFFF39200),
                ),
              ),
              Positioned(
                left: -54 * sx,
                top: 339 * sy,
                width: 183 * sx,
                height: 189 * sy,
                child: _CircleDecor(
                  color: const Color(0xFF010F46).withValues(alpha: 0.43),
                ),
              ),
              Positioned(
                left: 179 * sx,
                top: 72 * sy,
                width: 207 * sx,
                height: 206 * sy,
                child: _CircleDecor(
                  color: const Color(0x6EFFC94A).withValues(alpha: 0.43),
                ),
              ),
              if (!isDark)
                Positioned(
                  left: 291 * sx,
                  top: 183 * sy,
                  width: 95 * sx,
                  height: 88 * sy,
                  child: const _CircleDecor(color: Color(0xFFF39200)),
                ),
              Positioned.fill(
                child: Container(
                  color: isDark
                      ? const Color(0x42000000)
                      : const Color(0x42FFFFFF),
                ),
              ),
              Positioned(
                left: 42 * sx,
                top: 180 * sy,
                width: 344 * sx,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    30 * sx,
                    18 * sy,
                    30 * sx,
                    22 * sy,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    gradient: const LinearGradient(
                      begin: Alignment(-0.95, -0.95),
                      end: Alignment(1, 1),
                      colors: [Color(0x33D9D9D9), Color(0x334F4E4E)],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/Logo.png',
                        width: 116 * sx,
                        height: 132 * sy,
                      ),
                      const SizedBox(height: 6),
                      const _GradientText(
                        'ICTU COMMUNITY',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const _GradientText(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 18 * sy),
                      _LabeledInput(
                        label: 'Full Name',
                        isDark: isDark,
                        controller: _nameController,
                      ),
                      SizedBox(height: 10 * sy),
                      _LabeledInput(
                        label: 'Email Address',
                        isDark: isDark,
                        controller: _emailController,
                      ),
                      SizedBox(height: 10 * sy),
                      _LabeledInput(
                        label: 'Password',
                        isDark: isDark,
                        controller: _passwordController,
                        obscureText: true,
                      ),
                      SizedBox(height: 10 * sy),
                      _LabeledInput(
                        label: 'Confirm Password',
                        isDark: isDark,
                        controller: _confirmPasswordController,
                        obscureText: true,
                      ),
                      const SizedBox(height: 6),
                      // Keep these as defaults to satisfy the backend contract.
                      // We use small, unobtrusive selectors so the UI doesn't shift much.
                      Row(
                        children: [
                          Expanded(
                            child: _CompactDropdown<String>(
                              label: 'Role',
                              isDark: isDark,
                              value: _role,
                              items: const [
                                DropdownMenuItem(
                                  value: 'student',
                                  child: Text('Student'),
                                ),
                                DropdownMenuItem(
                                  value: 'delegate',
                                  child: Text('Delegate'),
                                ),
                                DropdownMenuItem(
                                  value: 'lecturer',
                                  child: Text('Lecturer'),
                                ),
                              ],
                              onChanged: (v) => setState(() => _role = v ?? _role),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _CompactTextInput(
                              label: 'Faculty',
                              isDark: isDark,
                              initialValue: _faculty,
                              onChanged: (v) => _faculty = v.trim().isEmpty ? _faculty : v.trim(),
                            ),
                          ),
                        ],
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorText!,
                          style: const TextStyle(
                            color: Color(0xFFF87171),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      SizedBox(height: 14 * sy),
                      ValueListenableBuilder<bool>(
                        valueListenable: _authController.isLoading,
                        builder: (context, loading, _) {
                          return SizedBox(
                            width: 222 * sx,
                            height: 37 * sy,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(54),
                                gradient: const LinearGradient(
                                  colors: [Color(0x91D49100), Color(0x9114154C)],
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(54),
                                  onTap: loading ? null : _onSignup,
                                  child: Center(
                                    child: Text(
                                      loading ? 'Creating...' : 'Sign Up',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 28,
                                        height: 1,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 6.4,
                                            offset: Offset(0, 4),
                                            color: Color(0x40000000),
                                          ),
                                          Shadow(
                                            blurRadius: 4,
                                            offset: Offset(0, 4),
                                            color: Color(0x40000000),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Already have an account? Login',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFA6FFB6)
                                : const Color(0xFF334155),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 51 * sy,
                left: 14 * sx,
                child: Container(
                  width: 42 * sx,
                  height: 41 * sy,
                  decoration: const BoxDecoration(
                    color: Color(0x6ED9D9D9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 18,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 10 * sy,
                child: Center(
                  child: Container(
                    width: 128 * sx,
                    height: 6 * sy,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
    required this.controller,
    required this.label,
    required this.isDark,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final bool isDark;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white : Colors.black,
            fontFamily: 'Kode Mono',
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 31,
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 12,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              filled: true,
              fillColor: const Color(0x82D9D9D9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFF59E0B),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleDecor extends StatelessWidget {
  const _CircleDecor({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _GradientText extends StatelessWidget {
  const _GradientText(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) => const LinearGradient(
        colors: [Color(0xFFA6FFB6), Color(0xFF636999)],
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(text, style: style),
    );
  }
}

class _CompactDropdown<T> extends StatelessWidget {
  const _CompactDropdown({
    required this.label,
    required this.isDark,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final bool isDark;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white : Colors.black,
            fontFamily: 'Kode Mono',
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 31,
          child: DropdownButtonFormField<T>(
            initialValue: value,
            items: items,
            onChanged: onChanged,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              filled: true,
              fillColor: const Color(0x82D9D9D9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFF59E0B),
                  width: 1,
                ),
              ),
            ),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 12,
            ),
            dropdownColor: const Color(0xFFCBD5E1),
            iconEnabledColor: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }
}

class _CompactTextInput extends StatefulWidget {
  const _CompactTextInput({
    required this.label,
    required this.isDark,
    required this.initialValue,
    required this.onChanged,
  });

  final String label;
  final bool isDark;
  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<_CompactTextInput> createState() => _CompactTextInputState();
}

class _CompactTextInputState extends State<_CompactTextInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 11,
            color: widget.isDark ? Colors.white : Colors.black,
            fontFamily: 'Kode Mono',
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 31,
          child: TextField(
            controller: _controller,
            onChanged: widget.onChanged,
            style: TextStyle(
              color: widget.isDark ? Colors.white : Colors.black,
              fontSize: 12,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              filled: true,
              fillColor: const Color(0x82D9D9D9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFF59E0B),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

