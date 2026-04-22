class Validators {
  static String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? urlValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'API URL is required';
    }
    final urlRegex = RegExp(r'^https?://[^\s]+$');
    if (!urlRegex.hasMatch(value)) {
      return 'Enter a valid URL (must start with http:// or https://)';
    }
    return null;
  }
}
