import 'package:flutter_workshop_front/core/format/br_format.dart';
import 'package:flutter_workshop_front/core/money/money.dart';
import 'package:flutter_workshop_front/core/validators/cpf_validator.dart';
import 'package:flutter_workshop_front/core/validators/text_validators.dart';

/// Validadores de `FormField` com o texto de erro centralizado. Cada um
/// devolve `null` quando o valor é aceito.
abstract final class FormValidators {
  static const requiredName = 'Por favor, insira o nome';
  static const requiredCpf = 'Por favor, insira o CPF';
  static const invalidCpf = 'CPF inválido';
  static const invalidEmail = 'O email é inválido';
  static const requiredMainPhone = 'O telefone principal é obrigatório';
  static const incompletePhone = 'Telefone incompleto';
  static const invalidMoney = 'Valor inválido';
  static const requiredProblem = 'O campo problema é obrigatório';

  /// Telefone brasileiro completo tem ao menos DDD + 8 dígitos.
  static const _minPhoneDigits = 10;

  /// Texto não vazio (ignora espaços); [message] é o erro.
  static FormFieldValidatorString required(String message) =>
      (value) => TextValidators.hasText(value) ? null : message;

  static String? name(String? value) => required(requiredName)(value);

  static String? problem(String? value) => required(requiredProblem)(value);

  /// CPF obrigatório e com dígitos verificadores corretos.
  static String? cpf(String? value) {
    if (value == null || value.isEmpty) return requiredCpf;
    return CpfValidator.isValid(value) ? null : invalidCpf;
  }

  /// Email opcional: vazio é aceito, preenchido precisa ser válido.
  static String? optionalEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    return TextValidators.isEmail(value) ? null : invalidEmail;
  }

  /// Telefone principal: obrigatório e com ao menos 10 dígitos.
  static String? mainPhone(String? value) {
    if (value == null || value.isEmpty) return requiredMainPhone;
    return _phoneIsComplete(value) ? null : incompletePhone;
  }

  /// Telefone secundário: vazio é aceito, preenchido precisa estar completo.
  static String? optionalPhone(String? value) {
    if (value == null || value.isEmpty) return null;
    return _phoneIsComplete(value) ? null : incompletePhone;
  }

  /// Valor em reais opcional: vazio é aceito, preenchido precisa ser um
  /// valor BR (`1.234,56`).
  static String? optionalMoney(String? value) {
    if (value == null || value.isEmpty) return null;
    return Money.tryParseBr(value) == null ? invalidMoney : null;
  }

  static bool _phoneIsComplete(String value) =>
      BrFormat.digitsOnly(value).length >= _minPhoneDigits;
}

typedef FormFieldValidatorString = String? Function(String? value);
