export '../forms/formz_inputs.dart';

class Validators {
  static const Set<String> disposableEmailDomains = {
    'mailinator.com',
    'tempmail.com',
    'temp-mail.org',
    '10minutemail.com',
    'guerrillamail.com',
    'sharklasers.com',
    'throwawaymail.com',
    'yopmail.com',
    'trashmail.com',
    'getairmail.com',
    'dispostable.com',
    'burnermail.io',
    'dropmail.me',
    'fakeinbox.com',
    'mohmal.com',
    'crazymailing.com',
    'mytemp.email',
    'emailondeck.com',
    'tempail.com',
    'getnada.com',
    'inboxkitten.com',
    'mailnesia.com',
    'maildrop.cc',
    'discard.email',
    'trashmail.net',
    'nada.ltd',
    'nada.email',
    'generator.email',
    'byom.de',
    'guerrillamailblock.com',
    'pokemail.net',
    'spam4.me',
    'grr.la',
  };

  static bool isDisposableEmail(String email) {
    final trimmed = email.trim().toLowerCase();
    if (!trimmed.contains('@')) return false;
    final domain = trimmed.split('@').last.trim();
    return disposableEmailDomains.contains(domain);
  }

  static String? validateIndianPhone(String? value, {bool required = false}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return required ? 'Phone number is required' : null;

    var digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length != 10) return 'Enter a valid 10-digit Indian mobile number';
    if (!RegExp(r'^[6-9]').hasMatch(digits)) return 'Indian mobile numbers start with 6-9';
    return null;
  }

  static String? validateEmail(String? value, {bool required = false}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return required ? 'Email is required' : null;
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(text)) {
      return 'Enter a valid email address';
    }
    if (isDisposableEmail(text)) {
      return 'Disposable / temporary emails are not allowed';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validatePositiveInt(String? value, String fieldName, {int min = 1, int? max}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final num = int.tryParse(value.trim());
    if (num == null) {
      return '$fieldName must be a valid number';
    }
    if (num < min) {
      return '$fieldName must be at least $min';
    }
    if (max != null && num > max) {
      return '$fieldName cannot exceed $max';
    }
    return null;
  }

  static String? validateUsername(String? value, {int minLength = 3}) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < minLength) {
      return 'Username must be at least $minLength characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(trimmed)) {
      return 'Username can only contain letters, numbers, dots, dashes, and underscores';
    }
    return null;
  }

  static String? validatePassword(String? value, {int minLength = 6, String? username}) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(trimmed);
    final hasNumber = RegExp(r'[0-9]').hasMatch(trimmed);
    final hasSymbol = RegExp(r'[^a-zA-Z0-9\s]').hasMatch(trimmed);

    if (!hasLetter) {
      return 'Password must contain at least one letter';
    }
    if (!hasNumber) {
      return 'Password must contain at least one number';
    }
    if (!hasSymbol) {
      return 'Password must contain at least one symbol (e.g. @, #, \$, !)';
    }
    if (username != null && username.trim().isNotEmpty && trimmed.toLowerCase() == username.trim().toLowerCase()) {
      return 'Username and password cannot be identical';
    }
    return null;
  }
}

// Top-level aliases for backward compatibility
String? validateIndianPhone(String? value, {bool required = false}) =>
    Validators.validateIndianPhone(value, required: required);

String? validateEmail(String? value, {bool required = false}) =>
    Validators.validateEmail(value, required: required);

String? validateRequired(String? value, String fieldName) =>
    Validators.validateRequired(value, fieldName);

String? validatePositiveInt(String? value, String fieldName, {int min = 1, int? max}) =>
    Validators.validatePositiveInt(value, fieldName, min: min, max: max);

String? validateUsername(String? value, {int minLength = 3}) =>
    Validators.validateUsername(value, minLength: minLength);

String? validatePassword(String? value, {int minLength = 6, String? username}) =>
    Validators.validatePassword(value, minLength: minLength, username: username);