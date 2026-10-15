import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/core/utils/phone_utils.dart';

void main() {
  group('PhoneUtils — Tanzania Mobile Phone Normalization & Validation', () {
    test('Normalizes standard 07XXXXXXXX format to 2557XXXXXXXX', () {
      expect(PhoneUtils.normalizeTanzaniaPhone('0712345678'), '255712345678');
      expect(PhoneUtils.normalizeTanzaniaPhone('0784123456'), '255784123456');
    });

    test('Normalizes standard 06XXXXXXXX format to 2556XXXXXXXX', () {
      expect(PhoneUtils.normalizeTanzaniaPhone('0682812345'), '255682812345');
      expect(PhoneUtils.normalizeTanzaniaPhone('0655123456'), '255655123456');
    });

    test('Handles +255 and 255 prefixes correctly', () {
      expect(PhoneUtils.normalizeTanzaniaPhone('+255712345678'), '255712345678');
      expect(PhoneUtils.normalizeTanzaniaPhone('255682812345'), '255682812345');
    });

    test('Strips spaces, hyphens, and parentheses', () {
      expect(PhoneUtils.normalizeTanzaniaPhone('0712 345 678'), '255712345678');
      expect(PhoneUtils.normalizeTanzaniaPhone('+255 (682) 812-345'), '255682812345');
      expect(PhoneUtils.normalizeTanzaniaPhone('0784-123-456'), '255784123456');
    });

    test('Normalizes 9-digit local numbers without leading 0', () {
      expect(PhoneUtils.normalizeTanzaniaPhone('712345678'), '255712345678');
      expect(PhoneUtils.normalizeTanzaniaPhone('682812345'), '255682812345');
    });

    test('Validates valid Tanzania mobile numbers', () {
      expect(PhoneUtils.isValidTanzaniaPhone('0712345678'), isTrue);
      expect(PhoneUtils.isValidTanzaniaPhone('0682812345'), isTrue);
      expect(PhoneUtils.isValidTanzaniaPhone('255712345678'), isTrue);
      expect(PhoneUtils.isValidTanzaniaPhone('+255682812345'), isTrue);
    });

    test('Rejects invalid phone numbers', () {
      expect(PhoneUtils.isValidTanzaniaPhone(''), isFalse);
      expect(PhoneUtils.isValidTanzaniaPhone('12345'), isFalse);
      expect(PhoneUtils.isValidTanzaniaPhone('0222123456'), isFalse); // Landline prefix
      expect(PhoneUtils.isValidTanzaniaPhone('0812345678'), isFalse); // Non-existent prefix
      expect(PhoneUtils.isValidTanzaniaPhone('254712345678'), isFalse); // Kenya country code
      expect(PhoneUtils.isValidTanzaniaPhone('071234567890'), isFalse); // Too long
    });

    test('validatePhone returns correct bilingual error messages', () {
      expect(PhoneUtils.validatePhone(null, lang: 'sw'), 'Tafadhali ingiza nambari ya simu');
      expect(PhoneUtils.validatePhone(null, lang: 'en'), 'Please enter a phone number');

      expect(
        PhoneUtils.validatePhone('12345', lang: 'sw'),
        'Namba ya simu si sahihi (mfano: 07XXXXXXXX au 06XXXXXXXX)',
      );
      expect(
        PhoneUtils.validatePhone('12345', lang: 'en'),
        'Invalid phone number (e.g., 07XXXXXXXX or 06XXXXXXXX)',
      );

      expect(PhoneUtils.validatePhone('0712345678', lang: 'sw'), isNull);
      expect(PhoneUtils.validatePhone('0712345678', lang: 'en'), isNull);
    });

    test('formatForDisplay formats phone numbers nicely', () {
      expect(PhoneUtils.formatForDisplay('0712345678'), '+255 712 345 678');
      expect(PhoneUtils.formatForDisplay('255682812345'), '+255 682 812 345');
    });
  });
}
