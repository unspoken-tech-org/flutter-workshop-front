import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/currency_input_formatter.dart';
import 'package:intl/intl.dart';

void main() {
  group('fromCurrency', () {
    test('converte valores com separador de milhar', () {
      expect('1.500,00'.fromCurrency(), 1500.0);
      expect('R\$ 12.345,67'.fromCurrency(), 12345.67);
    });

    test('converte o texto gerado pelo CurrencyInputFormatter', () {
      final formatted = CurrencyInputFormatter().formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '150000'),
      );

      expect(formatted.text.fromCurrency(), 1500.0);
    });

    test(
      'converte o texto gerado pelo NumberFormat pt_BR (espaço não separável)',
      () {
        final formatted = NumberFormat.currency(
          locale: 'pt_BR',
          symbol: 'R\$',
        ).format(1500);

        expect(formatted.fromCurrency(), 1500.0);
      },
    );

    test('campo vazio vira 0 sem lançar', () {
      expect(''.fromCurrency(), 0);
    });
  });
}
