/// Client-side validation helpers that mirror our Supabase Edge Functions.
///
/// Backend reference:
/// - `supabase/functions/register/index.ts`
/// - `supabase/functions/login/index.ts`
library;

class AuthValidation {
  AuthValidation._();

  // Keep in sync with the backend email validator.
  // Backend currently accepts ICT University emails.
  static const List<String> allowedEmailDomains = <String>[
    '@ictuniversity.edu.cm'
  ];

  /// Returns an error message if the email is invalid, otherwise null.
  static String? validateIctuEmail(String email) {
    final v = email.trim();
    if (v.isEmpty) return 'Email is required.';

    // Basic email pattern (kept intentionally simple).
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(v)) return 'Please enter a valid email address.';

    final lower = v.toLowerCase();
    final ok = allowedEmailDomains.any(lower.endsWith);
    if (!ok) {
      final domains = allowedEmailDomains.join(' or ');
      return 'Use your university email ($domains).';
    }
    return null;
  }

  /// Mirrors backend password strength rules (at minimum).
  ///
  /// Enforced:
  /// - min length 8
  /// - at least 1 uppercase
  /// - at least 1 lowercase
  /// - at least 1 digit
  /// - at least 1 special char
  static String? validateStrongPassword(String password) {
    if (password.isEmpty) return 'Password is required.';
    if (password.length < 8) return 'Password must be at least 8 characters.';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must include an uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must include a lowercase letter.';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Password must include a number.';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Password must include a special character.';
    }
    return null;
  }

  static String? validateFullName(String name) {
    final v = name.trim();
    if (v.isEmpty) return 'Full name is required.';
    if (v.length < 2) return 'Full name is too short.';
    return null;
  }

  static String? validateConfirmPassword(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) return 'Please confirm your password.';
    if (password != confirmPassword) return 'Passwords do not match.';
    return null;
  }
}

