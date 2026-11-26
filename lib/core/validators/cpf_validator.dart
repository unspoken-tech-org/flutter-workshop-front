class CpfValidator {
  static bool isValid(String cpf) {
    final numbers = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbers.length != 11) {
      return false;
    }

    if (RegExp(r'^(\d)\1*$').hasMatch(numbers)) {
      return false;
    }

    final digits = numbers.split('').map((d) => int.parse(d)).toList();

    var sum = 0;
    for (var i = 0; i < 9; i++) {
      sum += digits[i] * (10 - i);
    }
    var firstCheckDigit = (sum * 10) % 11;
    if (firstCheckDigit == 10) {
      firstCheckDigit = 0;
    }

    if (digits[9] != firstCheckDigit) {
      return false;
    }

    sum = 0;
    for (var i = 0; i < 10; i++) {
      sum += digits[i] * (11 - i);
    }
    var secondCheckDigit = (sum * 10) % 11;
    if (secondCheckDigit == 10) {
      secondCheckDigit = 0;
    }

    if (digits[10] != secondCheckDigit) {
      return false;
    }

    return true;
  }
}
