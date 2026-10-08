/// Form validators. Each returns an error message, or null when valid.
class Validators {
  Validators._();

  static String? required(String? value, [String label = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? maxLength(String? value, int max) {
    if (value != null && value.trim().length > max) {
      return 'Keep this under $max characters';
    }
    return null;
  }

  static String? email(String? value) {
    final error = required(value, 'Email');
    if (error != null) return error;
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim());
    return valid ? null : 'Enter a valid email address';
  }

  /// A number within [min]..[max] (inclusive). [max] is optional.
  static String? number(String? value, {required num min, num? max}) {
    final parsed = num.tryParse((value ?? '').trim());
    if (parsed == null) return 'Enter a number';
    if (parsed < min) return 'Must be at least $min';
    if (max != null && parsed > max) return 'Must be at most $max';
    return null;
  }

  /// Optional Indian mobile number: empty, or 10 digits starting 6-9.
  static String? optionalIndianMobile(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    return RegExp(r'^[6-9]\d{9}$').hasMatch(text)
        ? null
        : 'Enter a 10-digit mobile number';
  }

  /// Optional Instagram handle: letters, digits, dots and underscores.
  static String? optionalInstagram(String? value) {
    final text = (value ?? '').trim().replaceFirst('@', '');
    if (text.isEmpty) return null;
    return RegExp(r'^[A-Za-z0-9._]{1,30}$').hasMatch(text)
        ? null
        : 'Enter a valid Instagram handle';
  }
}
