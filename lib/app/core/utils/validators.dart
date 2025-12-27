/// Input validators
class Validators {
  Validators._();

  /// Email regex pattern
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Validate email format
  static bool isValidEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    return _emailRegex.hasMatch(email.trim());
  }

  /// Validate token format (non-empty, min length)
  static bool isValidToken(String? token) {
    if (token == null || token.isEmpty) return false;
    return token.trim().length >= 10;
  }

  /// Validate display name
  static bool isValidDisplayName(String? name) {
    if (name == null || name.isEmpty) return false;
    final trimmed = name.trim();
    return trimmed.length >= 2 && trimmed.length <= 50;
  }

  /// Validate deck name
  static bool isValidDeckName(String? name) {
    if (name == null || name.isEmpty) return false;
    return name.trim().isNotEmpty && name.trim().length <= 100;
  }
}
