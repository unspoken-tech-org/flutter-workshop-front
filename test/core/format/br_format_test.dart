import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/format/br_format.dart';

void main() {
  group('BrFormat.date', () {
    test('formata e lê dd/MM/yyyy', () {
      expect(BrFormat.date(DateTime(2026, 3, 5)), '05/03/2026');
      expect(BrFormat.parseDate('05/03/2026'), DateTime(2026, 3, 5));
    });

    test('tryParseDate rejeita datas impossíveis e texto livre', () {
      expect(BrFormat.tryParseDate('31/02/2026'), isNull);
      expect(BrFormat.tryParseDate('abc'), isNull);
      expect(BrFormat.tryParseDate('28/02/2026'), DateTime(2026, 2, 28));
    });
  });

  group('BrFormat.digitsOnly', () {
    test('mantém só os dígitos', () {
      expect(BrFormat.digitsOnly('(11) 91234-5678'), '11912345678');
      expect(BrFormat.digitsOnly(null), '');
    });
  });

  group('BrFormat.phone', () {
    test('formata 11 e 10 dígitos', () {
      expect(BrFormat.phone('11912345678'), '(11) 91234-5678');
      expect(BrFormat.phone('1132345678'), '(11) 3234-5678');
    });

    test('devolve o texto original quando não cabe no formato', () {
      expect(BrFormat.phone('12345'), '12345');
      expect(BrFormat.phone(null), '');
    });
  });

  group('BrFormat.cpf', () {
    test('formata 11 dígitos, com ou sem máscara', () {
      expect(BrFormat.cpf('52998224725'), '529.982.247-25');
      expect(BrFormat.cpf('529.982.247-25'), '529.982.247-25');
    });

    test('devolve o texto original quando não tem 11 dígitos', () {
      expect(BrFormat.cpf('123'), '123');
      expect(BrFormat.cpf(null), '');
    });
  });
}
