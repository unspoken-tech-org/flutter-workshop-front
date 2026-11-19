import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/utils/filter_utils.dart';

void main() {
  group('FilterUtils', () {
    group('names with spaces, accents, and punctuation', () {
      test('preserves spaces and accents in text', () {
        final filter = FilterUtils('Maria da Silva');

        expect(filter.text, 'Maria da Silva');
        expect(filter.isName, isTrue);
        expect(filter.isEmail, isFalse);
        expect(filter.isCpf, isFalse);
        expect(filter.isId, isFalse);
        expect(filter.isPhoneOrCellPhone, isFalse);
      });

      test('recognizes accented names like José and Conceição', () {
        for (final name in [
          'José',
          'Conceição',
          'João Pedro',
          'Ana-Clara',
          "D'Ávila",
        ]) {
          final filter = FilterUtils(name);
          expect(filter.isName, isTrue, reason: '$name should be a name');
          expect(filter.text, name);
        }
      });

      test('trims outer spaces and collapses consecutive spaces', () {
        final filter = FilterUtils('  Maria   da   Silva  ');

        expect(filter.text, 'Maria da Silva');
        expect(filter.isName, isTrue);
      });
    });

    group('CPF detection', () {
      test('accepts formatted and unformatted valid CPF and strips mask', () {
        final formatted = FilterUtils('529.982.247-25');
        final raw = FilterUtils('52998224725');
        final spaced = FilterUtils('  529.982.247-25  ');

        for (final filter in [formatted, raw, spaced]) {
          expect(filter.isCpf, isTrue);
          expect(filter.digits, '52998224725');
          expect(filter.isPhoneOrCellPhone, isFalse);
          expect(filter.isName, isFalse);
        }
      });

      test('rejects repeated-digit CPFs and invalid check digits', () {
        for (final invalid in [
          '111.111.111-11',
          '11111111111',
          '000.000.000-00',
          '529.982.247-00',
        ]) {
          final filter = FilterUtils(invalid);
          expect(filter.isCpf, isFalse, reason: '$invalid must not be CPF');
        }
      });
    });

    group('phone detection', () {
      test('accepts formatted and raw phones and extracts digits', () {
        final cases = {
          '(11) 98765-4321': '11987654321',
          '11987654321': '11987654321',
          '3333-4444': '33334444',
          '(11) 3333-4444': '1133334444',
        };

        for (final entry in cases.entries) {
          final filter = FilterUtils(entry.key);
          expect(
            filter.isPhoneOrCellPhone,
            isTrue,
            reason: '${entry.key} should be phone',
          );
          expect(filter.digits, entry.value);
          expect(filter.isCpf, isFalse);
          expect(filter.isName, isFalse);
        }
      });
    });

    group('email detection', () {
      test('preserves email characters and rejects as name', () {
        final filter = FilterUtils('  maria.silva+teste@empresa.com.br  ');

        expect(filter.isEmail, isTrue);
        expect(filter.text, 'maria.silva+teste@empresa.com.br');
        expect(filter.isName, isFalse);
      });
    });

    group('ID detection', () {
      test('recognizes up to 7 digits even with surrounding spaces', () {
        final filter = FilterUtils('  42  ');

        expect(filter.isId, isTrue);
        expect(filter.digits, '42');
        expect(filter.text, '42');
      });

      test('treats 8 digits as phone instead of ID', () {
        final filter = FilterUtils('12345678');

        expect(filter.isId, isFalse);
        expect(filter.isPhoneOrCellPhone, isTrue);
      });
    });

    group('empty and punctuation strings', () {
      test('returns false for all types when empty or punctuation-only', () {
        for (final input in ['', '   ', '---', '...']) {
          final filter = FilterUtils(input);
          expect(filter.isName, isFalse);
          expect(filter.isEmail, isFalse);
          expect(filter.isCpf, isFalse);
          expect(filter.isId, isFalse);
          expect(filter.isPhoneOrCellPhone, isFalse);
        }
      });
    });
  });
}
