/// Input validation helper functions for forms.
abstract final class Validators {
  /// Validates that the input is not empty.
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required.';
    }
    return null;
  }

  /// Validates that the input is a valid email address.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  /// Validates password strength (min length).
  static String? password(String? value, [int minLength = 6]) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters long.';
    }
    return null;
  }

  /// Validates that value has a minimum length.
  static String? minLength(String? value, int min, [String? fieldName]) {
    if (value == null || value.trim().length < min) {
      return '${fieldName ?? 'This field'} must be at least $min characters.';
    }
    return null;
  }

  /// Validates that value has a maximum length.
  static String? maxLength(String? value, int max, [String? fieldName]) {
    if (value != null && value.trim().length > max) {
      return '${fieldName ?? 'This field'} cannot exceed $max characters.';
    }
    return null;
  }
}
