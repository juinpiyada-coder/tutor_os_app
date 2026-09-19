import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/utils/validators.dart';

void main() {
  group('Password Validation (TOS-AUTH-01 & TOS-AUTH-02)', () {
    test('Rejects empty password', () {
      expect(Validators.validatePassword(''), isNotNull);
      expect(Validators.validatePassword(null), isNotNull);
    });

    test('Rejects password shorter than 6 characters', () {
      final res = Validators.validatePassword('Ab1@');
      expect(res, 'Password must be at least 6 characters');
    });

    test('Rejects password with no letters', () {
      final res = Validators.validatePassword('123456@#');
      expect(res, 'Password must contain at least one letter');
    });

    test('Rejects password with no numbers', () {
      final res = Validators.validatePassword('Abcdef@#');
      expect(res, 'Password must contain at least one number');
    });

    test('Rejects password with no symbols', () {
      final res = Validators.validatePassword('Abcdef12');
      expect(res, 'Password must contain at least one symbol (e.g. @, #, \$, !)');
    });

    test('Rejects password identical to username', () {
      final res = Validators.validatePassword('Pass@123', username: 'Pass@123');
      expect(res, 'Username and password cannot be identical');
    });

    test('Accepts valid alphanumeric password with symbol >= 6 chars', () {
      final res = Validators.validatePassword('Pass@123', username: 'john_doe');
      expect(res, isNull);
    });
  });

  group('Contact Info Validation (TOS-STUDENT-02 & TOS-PARENT-01)', () {
    test('Validates Indian phone numbers correctly', () {
      expect(Validators.validateIndianPhone('9876543210'), isNull);
      expect(Validators.validateIndianPhone('+91 98765 43210'), isNull);
      expect(Validators.validateIndianPhone('09876543210'), isNull);

      expect(Validators.validateIndianPhone('1234567890'), 'Indian mobile numbers start with 6-9');
      expect(Validators.validateIndianPhone('98765'), 'Enter a valid 10-digit Indian mobile number');
      expect(Validators.validateIndianPhone('', required: true), 'Phone number is required');
      expect(Validators.validateIndianPhone('', required: false), isNull);
    });

    test('Validates email addresses correctly', () {
      expect(Validators.validateEmail('test@example.com'), isNull);
      expect(Validators.validateEmail('user.name+tag@sub.domain.org'), isNull);
      expect(Validators.validateEmail('invalid-email'), 'Enter a valid email address');
      expect(Validators.validateEmail('', required: true), 'Email is required');
      expect(Validators.validateEmail('', required: false), isNull);
    });

    test('Validates required fields and positive integers', () {
      expect(Validators.validateRequired('Science', 'Batch Name'), isNull);
      expect(Validators.validateRequired('', 'Batch Name'), 'Batch Name is required');
      expect(Validators.validatePositiveInt('30', 'Capacity', min: 1, max: 100), isNull);
      expect(Validators.validatePositiveInt('0', 'Capacity', min: 1), 'Capacity must be at least 1');
      expect(Validators.validatePositiveInt('150', 'Capacity', min: 1, max: 100), 'Capacity cannot exceed 100');
    });
  });
}

