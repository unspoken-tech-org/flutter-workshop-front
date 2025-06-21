class FilterUtils {
  final String term;

  FilterUtils(this.term);

  bool get _isNumber {
    // Define a RegEx para números
    final regex = RegExp(r'^[0-9]+$');
    return regex.hasMatch(term);
  }

  bool get isCpf {
    final cpfRegex = RegExp(r'^(\d{3}\.?\d{3}\.?\d{3}-?\d{2})$');
    return cpfRegex.hasMatch(term);
  }

  bool get isName {
    // Define a RegEx para letras (maiúsculas e minúsculas)
    final regex = RegExp(r'^[a-zA-Z]+$');
    return regex.hasMatch(term);
  }

  bool get isId {
    return _isNumber && term.length <= 7;
  }

  bool get isPhoneOrCellPhone {
    final isNumber = _isNumber;
    final isLength = term.length >= 8 && term.length <= 11;

    return isNumber && isLength;
  }
}
