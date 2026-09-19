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
}
