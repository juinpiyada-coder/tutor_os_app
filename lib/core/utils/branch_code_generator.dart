/// Generates human-readable branch codes from a coaching center name.
///
/// Format: `<COACHINGCENTERNAME>-<NNN>` (for example `APEXACADEMY-001`).
class BranchCodeGenerator {
  BranchCodeGenerator._();

  static const String fallbackPrefix = 'BR';

  /// Leaves room for the `-NNN` suffix inside the 50-character
  /// `branch_code` database column.
  static const int maxPrefixLength = 45;

  /// Returns the next available branch code for [coachingCenterName].
  ///
  /// Only existing codes that share the same coaching-center prefix are used
  /// to calculate the sequence. This prevents system-created branches such as
  /// `BR-MAIN`, or branches created under an older center name, from pushing
  /// the first real branch to `-002` or higher.
  ///
  /// [ignoreCode] is skipped while checking for collisions (useful while
  /// editing an existing branch so it does not collide with itself).
  static String next({
    required String coachingCenterName,
    required Iterable<String> existingCodes,
    String? ignoreCode,
  }) {
    var prefix = coachingCenterName
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (prefix.isEmpty) {
      prefix = fallbackPrefix;
    } else if (prefix.length > maxPrefixLength) {
      prefix = prefix.substring(0, maxPrefixLength);
    }

    final ignored = (ignoreCode ?? '').trim().toUpperCase();
    const numericSuffixPattern = r'-(\d+)$';
    final sequencePattern =
        RegExp('^${RegExp.escape(prefix)}$numericSuffixPattern');
    final usedCodes = <String>{};
    var highestNumber = 0;

    for (final rawCode in existingCodes) {
      final code = rawCode.trim().toUpperCase();
      if (code.isEmpty || code == ignored) continue;

      usedCodes.add(code);
      final match = sequencePattern.firstMatch(code);
      if (match != null) {
        final number = int.tryParse(match.group(1) ?? '') ?? 0;
        if (number > highestNumber) highestNumber = number;
      }
    }

    var nextNumber = highestNumber + 1;
    while (true) {
      final candidate =
          '$prefix-${nextNumber.toString().padLeft(3, '0')}';
      if (!usedCodes.contains(candidate)) return candidate;
      nextNumber++;
    }
  }
}
