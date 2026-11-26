import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/validators/form_validators.dart';

void main() {
  group('FormValidators.required / name / problem', () {
    test('rejeita nulo, vazio e só espaços com o texto dado', () {
      final validator = FormValidators.required('Obrigatório');

      expect(validator(null), 'Obrigatório');
      expect(validator(''), 'Obrigatório');
      expect(validator('   '), 'Obrigatório');
      expect(validator('ok'), isNull);
    });

    test('name e problem usam os textos centralizados', () {
      expect(FormValidators.name(' '), FormValidators.requiredName);
      expect(FormValidators.problem(null), FormValidators.requiredProblem);
      expect(FormValidators.name('Ana'), isNull);
    });
  });

  group('FormValidators.cpf', () {
    test('obrigatório, depois valida os dígitos verificadores', () {
      expect(FormValidators.cpf(null), FormValidators.requiredCpf);
      expect(FormValidators.cpf(''), FormValidators.requiredCpf);
      expect(FormValidators.cpf('111.111.111-11'), FormValidators.invalidCpf);
      expect(FormValidators.cpf('529.982.247-24'), FormValidators.invalidCpf);
      expect(FormValidators.cpf('529.982.247-25'), isNull);
    });
  });

  group('FormValidators.optionalEmail', () {
    test('vazio é aceito; preenchido precisa ser válido', () {
      expect(FormValidators.optionalEmail(null), isNull);
      expect(FormValidators.optionalEmail(''), isNull);
      expect(FormValidators.optionalEmail('a@b'), FormValidators.invalidEmail);
      expect(FormValidators.optionalEmail('a@b.com'), isNull);
    });
  });

  group('FormValidators.mainPhone / optionalPhone', () {
    test('principal é obrigatório e exige 10 dígitos', () {
      expect(FormValidators.mainPhone(''), FormValidators.requiredMainPhone);
      expect(
        FormValidators.mainPhone('(11) 9123'),
        FormValidators.incompletePhone,
      );
      expect(FormValidators.mainPhone('(11) 1234-5678'), isNull);
    });

    test('secundário vazio é aceito; preenchido exige 10 dígitos', () {
      expect(FormValidators.optionalPhone(''), isNull);
      expect(
        FormValidators.optionalPhone('123'),
        FormValidators.incompletePhone,
      );
      expect(FormValidators.optionalPhone('11912345678'), isNull);
    });
  });

  group('FormValidators.optionalMoney', () {
    test('vazio é aceito; preenchido precisa ser valor BR', () {
      expect(FormValidators.optionalMoney(''), isNull);
      expect(FormValidators.optionalMoney('1.234,56'), isNull);
      expect(FormValidators.optionalMoney('abc'), FormValidators.invalidMoney);
    });
  });
}
