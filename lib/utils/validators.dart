// utils/validators.dart
// Week 6 — Form validation & input sanitization

class Validators {
  Validators._();

  /// Recipe name: 3–80 chars, no leading/trailing whitespace,
  /// strips basic script injection patterns (XSS prevention — Week 11).
  static String? recipeName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Recipe name is required.';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'Name must be at least 3 characters.';
    }
    if (trimmed.length > 80) {
      return 'Name must be 80 characters or fewer.';
    }
    if (_containsScriptTags(trimmed)) {
      return 'Invalid characters detected.';
    }
    return null;
  }

  /// Notes / description: optional, max 500 chars, no script tags.
  static String? notes(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length > 500) {
      return 'Notes must be 500 characters or fewer.';
    }
    if (_containsScriptTags(value)) {
      return 'Invalid characters detected.';
    }
    return null;
  }

  /// PIN: 4–6 digits only.
  static String? pin(String? value) {
    if (value == null || value.isEmpty) return 'PIN is required.';
    if (value.length < 4) return 'PIN must be at least 4 digits.';
    if (value.length > 6) return 'PIN must be 6 digits or fewer.';
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'PIN must contain digits only.';
    }
    return null;
  }

  /// Sanitize a string for safe display (removes angle brackets).
  static String sanitize(String input) {
    return input.replaceAll('<', '&lt;').replaceAll('>', '&gt;');
  }

  // ── private ──────────────────────────────────────────────────────────────
  static bool _containsScriptTags(String value) {
    final lower = value.toLowerCase();
    return lower.contains('<script') ||
        lower.contains('javascript:') ||
        lower.contains('onerror=') ||
        lower.contains('onload=');
  }
}
