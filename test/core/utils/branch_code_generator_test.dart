import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/utils/branch_code_generator.dart';

void main() {
  group('BranchCodeGenerator.next', () {
    test('starts at 001 when only the auto-created BR-MAIN branch exists', () {
      final code = BranchCodeGenerator.next(
        coachingCenterName: 'Apex Academy',
        existingCodes: ['BR-MAIN'],
      );

      expect(code, 'APEXACADEMY-001');
    });

    test('increments based on branches with the same prefix only', () {
      final code = BranchCodeGenerator.next(
        coachingCenterName: 'Apex Academy',
        existingCodes: ['BR-MAIN', 'APEXACADEMY-001', 'APEXACADEMY-002'],
      );

      expect(code, 'APEXACADEMY-003');
    });

    test('ignores numeric suffixes that belong to another prefix', () {
      final code = BranchCodeGenerator.next(
        coachingCenterName: 'Apex Academy',
        existingCodes: ['BR-MAIN', 'OTHER-009'],
      );

      expect(code, 'APEXACADEMY-001');
    });

    test('skips a code that is already used', () {
      final code = BranchCodeGenerator.next(
        coachingCenterName: 'Apex',
        existingCodes: ['APEX-001', 'APEX-003'],
      );

      expect(code, 'APEX-004');
    });

    test('sanitizes the coaching center name', () {
      final code = BranchCodeGenerator.next(
        coachingCenterName: '  Apex & FitJEE Pvt. Ltd.  ',
        existingCodes: const [],
      );

      expect(code, 'APEXFITJEEPVTLTD-001');
    });

    test('falls back to BR when the name has no usable characters', () {
      final code = BranchCodeGenerator.next(
        coachingCenterName: '***',
        existingCodes: const [],
      );

      expect(code, 'BR-001');
    });

    test('does not collide with itself while editing', () {
      final code = BranchCodeGenerator.next(
        coachingCenterName: 'Apex',
        existingCodes: ['APEX-001', 'APEX-002'],
        ignoreCode: 'APEX-002',
      );

      expect(code, 'APEX-002');
    });

    test('keeps generated codes within the 50-character column limit', () {
      final code = BranchCodeGenerator.next(
        coachingCenterName: 'A' * 60,
        existingCodes: const [],
      );

      expect(code.length, lessThanOrEqualTo(50));
      expect(code.endsWith('-001'), isTrue);
    });
  });
}
