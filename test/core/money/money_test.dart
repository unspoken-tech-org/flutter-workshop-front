import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/money/money.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/currency_input_formatter.dart';

void main() {
  group('Money', () {
    test('avoids IEEE-754 precision errors on critical sums and diffs', () {
      expect(
        Money.fromReais(35.10) + Money.fromReais(66.67),
        Money.fromReais(101.77),
      );
      expect((Money.fromReais(35.10) + Money.fromReais(66.67)).cents, 10177);

      expect(
        Money.fromReais(70.10) + Money.fromReais(0.10),
        Money.fromReais(70.20),
      );
      expect((Money.fromReais(70.10) + Money.fromReais(0.10)).cents, 7020);

      expect(
        Money.fromReais(0.10) + Money.fromReais(0.20),
        Money.fromReais(0.30),
      );

      expect(
        Money.fromReais(101.77) - Money.fromReais(35.10),
        Money.fromReais(66.67),
      );
      expect(
        (Money.fromReais(101.77) - Money.fromReais(35.10)).isPositive,
        isTrue,
      );
      expect(
        (Money.fromReais(101.77) -
                Money.fromReais(35.10) -
                Money.fromReais(66.67))
            .isZero,
        isTrue,
      );
    });

    test('tryParseBr parses valid pt-BR currency formats', () {
      expect(Money.tryParseBr('R\$ 1.500,00'), const Money.fromCents(150000));
      expect(
        Money.tryParseBr('R\$\u00A01.500,00'),
        const Money.fromCents(150000),
      );
      expect(Money.tryParseBr('1500,5'), const Money.fromCents(150050));
      expect(Money.tryParseBr('1500'), const Money.fromCents(150000));
      expect(Money.tryParseBr('-10,00'), const Money.fromCents(-1000));
      expect(Money.tryParseBr('0,00'), Money.zero);
    });

    test('tryParseBr returns null for empty or invalid currency strings', () {
      for (final invalid in [
        null,
        '',
        '   ',
        'abc',
        'R\$',
        '10,123',
        '1.23',
        '1,2,3',
      ]) {
        expect(Money.tryParseBr(invalid), isNull, reason: 'input: $invalid');
      }
    });

    test('fromJson and toJson preserve exact reais representation', () {
      expect(Money.fromJson(101.77), const Money.fromCents(10177));
      expect(Money.fromJson(70.1), const Money.fromCents(7010));
      expect(Money.fromJson('101.77'), const Money.fromCents(10177));
      expect(Money.fromJson('R\$ 70,20'), const Money.fromCents(7020));
      expect(const Money.fromCents(10177).toJson(), 101.77);
      expect(const Money.fromCents(7020).toJson(), 70.2);

      expect(() => Money.fromJson('invalid'), throwsFormatException);
      expect(() => Money.fromJson(double.nan), throwsFormatException);
    });

    test('CurrencyInputFormatter uses integer cents without float drift', () {
      final formatter = CurrencyInputFormatter();
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '10177'),
      );
      expect(Money.tryParseBr(result.text), const Money.fromCents(10177));
    });
  });
}
