class FilterUtils {
  final String _term;

  FilterUtils(String term)
      : _term = term.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  String get term => _term;

  bool get _isNumber {
    // Define a RegEx para números
    final regex = RegExp(r'^[0-9]+$');
    return regex.hasMatch(_term);
  }

  bool get isCpf {
    final cpf = _term.replaceAll(RegExp(r'[^0-9]'), '');

    if (cpf.length != 11) {
      return false;
    }

    List<int> numbers = cpf.split('').map(int.parse).toList();
    int firstSum = 0;

    for (int i = 0; i < 9; i++) {
      firstSum += numbers[i] * (10 - i);
    }

    int firstDigit = (firstSum % 11 < 2) ? 0 : 11 - (firstSum % 11);

    if (firstDigit != numbers[9]) {
      return false;
    }

    int secondSum = 0;

    for (int i = 0; i < 10; i++) {
      secondSum += numbers[i] * (11 - i);
    }

    int secondDigit = (secondSum % 11 < 2) ? 0 : 11 - (secondSum % 11);

    if (secondDigit != numbers[10]) {
      return false;
    }

    return true;
  }

  bool get isName {
    // Define a RegEx para letras (maiúsculas e minúsculas)
    final regex = RegExp(r'^[a-zA-Z]+$');
    return regex.hasMatch(_term);
  }

  bool get isId {
    return _isNumber && _term.length <= 7;
  }

  bool get isPhoneOrCellPhone {
    final isNumber = _isNumber;
    final isLength = _term.length >= 8 && _term.length <= 11;

    return isNumber && isLength;
  }
}
