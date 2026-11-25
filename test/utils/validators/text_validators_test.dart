import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/utils/validators/text_validators.dart';

void main() {
  group('TextValidators.hasText', () {
    test('rejects null, empty and whitespace-only values', () {
      expect(TextValidators.hasText(null), isFalse);
      expect(TextValidators.hasText(''), isFalse);
      expect(TextValidators.hasText('   '), isFalse);
      expect(TextValidators.hasText('\t\n '), isFalse);
    });

    test('accepts values with visible characters', () {
      expect(TextValidators.hasText('Ana'), isTrue);
      expect(TextValidators.hasText('  Ana  '), isTrue);
    });
  });

  group('TextValidators.isEmail', () {
    test('accepts common addresses', () {
      expect(TextValidators.isEmail('ana@example.com'), isTrue);
      expect(
        TextValidators.isEmail('ana.silva+os@mail.example.com.br'),
        isTrue,
      );
      expect(TextValidators.isEmail(' ana@example.com '), isTrue);
    });

    test('rejects values that only contain an at sign', () {
      for (final value in [
        '@',
        'ana@',
        '@example.com',
        'ana@example',
        'ana silva@example.com',
        'ana@@example.com',
        'ana@exa mple.com',
      ]) {
        expect(TextValidators.isEmail(value), isFalse, reason: value);
      }
    });
  });
}
