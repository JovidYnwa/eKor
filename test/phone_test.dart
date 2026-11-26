import 'package:ekor/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validatePhone', () {
    test('rejects short numbers', () {
      expect(validatePhone('93512'), PhoneError.length);
    });

    test('rejects unknown operator codes', () {
      expect(validatePhone('335124407'), PhoneError.operator);
    });

    test('accepts valid Tajik numbers', () {
      for (final n in ['935124407', '905124407', '555124407', '005124407']) {
        expect(validatePhone(n), isNull, reason: n);
      }
    });
  });

  group('formatPhone', () {
    test('groups digits as XX XXX XX XX', () {
      expect(formatPhone('935124407'), '93 512 44 07');
    });

    test('formats partial input', () {
      expect(formatPhone('9'), '9');
      expect(formatPhone('9351'), '93 51');
      expect(formatPhone('935124'), '93 512 4');
    });
  });
}
