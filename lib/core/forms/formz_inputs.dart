import 'package:formz/formz.dart';

// ==========================================
// 1. REQUIRED FIELD INPUT
// ==========================================
enum RequiredValidationError { empty }

class RequiredInput extends FormzInput<String, RequiredValidationError> {
  const RequiredInput.pure([super.value = '']) : super.pure();
  const RequiredInput.dirty([super.value = '']) : super.dirty();

  @override
  RequiredValidationError? validator(String value) {
    return value.trim().isEmpty ? RequiredValidationError.empty : null;
  }

  String? get errorMessage {
    if (isPure || isValid) return null;
    return 'This field cannot be empty';
  }
}

// ==========================================
// 2. EMAIL INPUT
// ==========================================
enum EmailValidationError { empty, invalid }

class EmailInput extends FormzInput<String, EmailValidationError> {
  const EmailInput.pure([super.value = '']) : super.pure();
  const EmailInput.dirty([super.value = '']) : super.dirty();

  static final RegExp _emailRegExp = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  @override
  EmailValidationError? validator(String value) {
    if (value.trim().isEmpty) return EmailValidationError.empty;
    return _emailRegExp.hasMatch(value.trim()) ? null : EmailValidationError.invalid;
  }

  String? get errorMessage {
    if (isPure || isValid) return null;
    if (error == EmailValidationError.empty) return 'Email is required';
    if (error == EmailValidationError.invalid) return 'Enter a valid email address';
    return null;
  }
}

// ==========================================
// 3. PHONE INPUT (INDIAN 10-DIGIT MOBILE)
// ==========================================
enum PhoneValidationError { empty, invalidLength, invalidPrefix }

class PhoneInput extends FormzInput<String, PhoneValidationError> {
  const PhoneInput.pure([super.value = '']) : super.pure();
  const PhoneInput.dirty([super.value = '']) : super.dirty();

  @override
  PhoneValidationError? validator(String value) {
    final text = value.trim();
    if (text.isEmpty) return PhoneValidationError.empty;

    var digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length != 10) return PhoneValidationError.invalidLength;
    if (!RegExp(r'^[6-9]').hasMatch(digits)) return PhoneValidationError.invalidPrefix;
    return null;
  }

  String? get errorMessage {
    if (isPure || isValid) return null;
    if (error == PhoneValidationError.empty) return 'Phone number is required';
    if (error == PhoneValidationError.invalidLength) return 'Enter a valid 10-digit mobile number';
    if (error == PhoneValidationError.invalidPrefix) return 'Indian numbers start with 6, 7, 8, or 9';
    return null;
  }
}

// ==========================================
// 4. PASSWORD INPUT
// ==========================================
enum PasswordValidationError { empty, tooShort, missingAlphanumericSymbol, sameAsUsername }

class PasswordInput extends FormzInput<String, PasswordValidationError> {
  final int minLength;
  final String? username;
  const PasswordInput.pure({this.minLength = 6, this.username, String value = ''}) : super.pure(value);
  const PasswordInput.dirty({this.minLength = 6, this.username, String value = ''}) : super.dirty(value);

  @override
  PasswordValidationError? validator(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return PasswordValidationError.empty;
    if (trimmed.length < minLength) return PasswordValidationError.tooShort;

    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(trimmed);
    final hasNumber = RegExp(r'[0-9]').hasMatch(trimmed);
    final hasSymbol = RegExp(r'[^a-zA-Z0-9\s]').hasMatch(trimmed);

    if (!hasLetter || !hasNumber || !hasSymbol) {
      return PasswordValidationError.missingAlphanumericSymbol;
    }
    if (username != null && username!.trim().isNotEmpty && trimmed.toLowerCase() == username!.trim().toLowerCase()) {
      return PasswordValidationError.sameAsUsername;
    }
    return null;
  }

  String? get errorMessage {
    if (isPure || isValid) return null;
    if (error == PasswordValidationError.empty) return 'Password is required';
    if (error == PasswordValidationError.tooShort) return 'Must be at least $minLength characters';
    if (error == PasswordValidationError.missingAlphanumericSymbol) {
      return 'Password must contain letters, numbers, and symbols (e.g. Pass@123)';
    }
    if (error == PasswordValidationError.sameAsUsername) {
      return 'Username and password cannot be identical';
    }
    return null;
  }
}

// ==========================================
// 5. USERNAME INPUT
// ==========================================
enum UsernameValidationError { empty, tooShort, invalidChars }

class UsernameInput extends FormzInput<String, UsernameValidationError> {
  final int minLength;
  const UsernameInput.pure({this.minLength = 3, String value = ''}) : super.pure(value);
  const UsernameInput.dirty({this.minLength = 3, String value = ''}) : super.dirty(value);

  static final RegExp _usernameRegExp = RegExp(r'^[a-zA-Z0-9._-]+$');

  @override
  UsernameValidationError? validator(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return UsernameValidationError.empty;
    if (trimmed.length < minLength) return UsernameValidationError.tooShort;
    if (!_usernameRegExp.hasMatch(trimmed)) return UsernameValidationError.invalidChars;
    return null;
  }

  String? get errorMessage {
    if (isPure || isValid) return null;
    if (error == UsernameValidationError.empty) return 'Username is required';
    if (error == UsernameValidationError.tooShort) return 'Must be at least $minLength characters';
    if (error == UsernameValidationError.invalidChars) return 'Letters, numbers, dots, dashes only';
    return null;
  }
}

// ==========================================
// 6. POSITIVE NUMBER / AMOUNT INPUT
// ==========================================
enum NumberValidationError { empty, notNumber, belowMin, aboveMax }

class PositiveNumberInput extends FormzInput<String, NumberValidationError> {
  final int min;
  final int? max;

  const PositiveNumberInput.pure({this.min = 1, this.max, String value = ''}) : super.pure(value);
  const PositiveNumberInput.dirty({this.min = 1, this.max, String value = ''}) : super.dirty(value);

  @override
  NumberValidationError? validator(String value) {
    final text = value.trim();
    if (text.isEmpty) return NumberValidationError.empty;
    final num = int.tryParse(text);
    if (num == null) return NumberValidationError.notNumber;
    if (num < min) return NumberValidationError.belowMin;
    if (max != null && num > max!) return NumberValidationError.aboveMax;
    return null;
  }

  String? get errorMessage {
    if (isPure || isValid) return null;
    if (error == NumberValidationError.empty) return 'Value is required';
    if (error == NumberValidationError.notNumber) return 'Enter a valid integer';
    if (error == NumberValidationError.belowMin) return 'Minimum value is $min';
    if (error == NumberValidationError.aboveMax) return 'Maximum value is $max';
    return null;
  }
}
