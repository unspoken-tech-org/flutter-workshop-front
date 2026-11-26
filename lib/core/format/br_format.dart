import 'package:intl/intl.dart';

/// Fonte única dos formatos brasileiros (data, telefone, CPF) e de
/// `digitsOnly`. Dinheiro fica em `Money` (`toBrCurrency`, `tryParseBr`).
abstract final class BrFormat {
  static final DateFormat _date = DateFormat('dd/MM/yyyy');
  static final RegExp _nonDigits = RegExp(r'\D');

  /// `dd/MM/yyyy`.
  static String date(DateTime value) => _date.format(value);

  /// Lê `dd/MM/yyyy`; lança [FormatException] se o texto não for uma data.
  static DateTime parseDate(String text) => _date.parse(text);

  /// Lê `dd/MM/yyyy` rejeitando datas impossíveis (ex.: 31/02); `null` se
  /// inválida.
  static DateTime? tryParseDate(String text) => _date.tryParseStrict(text);

  /// Só os dígitos de [input]; vazio se `null`.
  static String digitsOnly(String? input) =>
      (input ?? '').replaceAll(_nonDigits, '');

  /// `(11) 91234-5678` ou `(11) 1234-5678`; devolve [input] se não tiver 10 ou
  /// 11 dígitos e `''` se for `null`.
  static String phone(String? input) {
    if (input == null) return '';
    final digits = digitsOnly(input);
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    }
    if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }
    return input;
  }

  /// `123.456.789-09`; devolve [input] se não tiver 11 dígitos e `''` se for
  /// `null`.
  static String cpf(String? input) {
    if (input == null) return '';
    final digits = digitsOnly(input);
    if (digits.length != 11) return input;
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
  }
}
