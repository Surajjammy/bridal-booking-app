import 'package:flutter_test/flutter_test.dart';
import 'package:makeup_booking_app/admin/core/utils/validators.dart';

void main() {
  group('Validators.required', () {
    test('rejects empty and whitespace', () {
      expect(Validators.required(null, 'Name'), 'Name is required');
      expect(Validators.required('   ', 'Name'), 'Name is required');
    });

    test('accepts text', () {
      expect(Validators.required('Priya'), isNull);
    });
  });

  group('Validators.email', () {
    test('accepts a normal address', () {
      expect(Validators.email('admin@example.com'), isNull);
    });

    test('rejects malformed addresses', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('admin'), isNotNull);
      expect(Validators.email('admin@example'), isNotNull);
    });
  });

  group('Validators.number', () {
    test('enforces the range', () {
      expect(Validators.number('0', min: 1), isNotNull);
      expect(Validators.number('5', min: 1, max: 10), isNull);
      expect(Validators.number('11', min: 1, max: 10), isNotNull);
    });

    test('rejects non-numbers', () {
      expect(Validators.number('abc', min: 1), 'Enter a number');
      expect(Validators.number('', min: 1), 'Enter a number');
    });
  });

  group('optional fields', () {
    test('empty is valid', () {
      expect(Validators.optionalIndianMobile(''), isNull);
      expect(Validators.optionalInstagram(null), isNull);
    });

    test('Indian mobile must be 10 digits starting 6-9', () {
      expect(Validators.optionalIndianMobile('9876543210'), isNull);
      expect(Validators.optionalIndianMobile('1234567890'), isNotNull);
      expect(Validators.optionalIndianMobile('98765'), isNotNull);
    });

    test('Instagram allows an optional @ and valid characters', () {
      expect(Validators.optionalInstagram('@priya.makeup_'), isNull);
      expect(Validators.optionalInstagram('priya makeup'), isNotNull);
    });
  });
}
