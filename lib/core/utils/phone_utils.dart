/// Utility functions for validating and normalizing Tanzanian mobile phone numbers.
class PhoneUtils {
  PhoneUtils._();

  /// Normalizes a raw phone number input into international format `255XXXXXXXXX`.
  /// Supports inputs like:
  /// - `07XXXXXXXX` -> `2557XXXXXXXX`
  /// - `06XXXXXXXX` -> `2556XXXXXXXX`
  /// - `+2557XXXXXXXX` -> `2557XXXXXXXX`
  /// - `2557XXXXXXXX` -> `2557XXXXXXXX`
  /// - `7XXXXXXXX` -> `2557XXXXXXXX`
  /// - Spaces, dashes, and parentheses are stripped out.
  static String normalizeTanzaniaPhone(String rawPhone) {
    if (rawPhone.isEmpty) return '';

    // Remove all whitespace, dashes, plus signs, brackets
    String cleaned = rawPhone.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');

    if (cleaned.startsWith('0')) {
      cleaned = '255${cleaned.substring(1)}';
    } else if ((cleaned.startsWith('7') || cleaned.startsWith('6')) && cleaned.length == 9) {
      cleaned = '255$cleaned';
    }

    return cleaned;
  }

  /// Validates whether the normalized or raw phone number is a valid Tanzanian mobile number.
  /// Valid format: 12 digits, starting with 255 followed by 6 or 7, then 8 digits.
  static bool isValidTanzaniaPhone(String rawPhone) {
    final normalized = normalizeTanzaniaPhone(rawPhone);
    final regex = RegExp(r'^255[67]\d{8}$');
    return regex.hasMatch(normalized);
  }

  /// Returns localized validation error message or null if valid.
  static String? validatePhone(String? rawPhone, {String lang = 'sw'}) {
    if (rawPhone == null || rawPhone.trim().isEmpty) {
      return lang == 'sw'
          ? 'Tafadhali ingiza nambari ya simu'
          : 'Please enter a phone number';
    }

    if (!isValidTanzaniaPhone(rawPhone)) {
      return lang == 'sw'
          ? 'Namba ya simu si sahihi (mfano: 07XXXXXXXX au 06XXXXXXXX)'
          : 'Invalid phone number (e.g., 07XXXXXXXX or 06XXXXXXXX)';
    }

    return null;
  }

  /// Formats a normalized phone number for readable display: `+255 7XX XXX XXX`.
  static String formatForDisplay(String phone) {
    final normalized = normalizeTanzaniaPhone(phone);
    if (normalized.length != 12) return phone;
    return '+${normalized.substring(0, 3)} ${normalized.substring(3, 6)} ${normalized.substring(6, 9)} ${normalized.substring(9, 12)}';
  }
}
