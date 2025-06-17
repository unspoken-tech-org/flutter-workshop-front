import 'package:flutter/services.dart';

class CpfFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length > 11) {
      return oldValue;
    }

    if (digitsOnly.isEmpty) {
      return const TextEditingValue();
    }

    final textToFormat = digitsOnly;
    final length = textToFormat.length;

    String result;

    if (length <= 3) {
      result = textToFormat;
    } else if (length <= 6) {
      result = '${textToFormat.substring(0, 3)}.${textToFormat.substring(3)}';
    } else if (length <= 9) {
      result =
          '${textToFormat.substring(0, 3)}.${textToFormat.substring(3, 6)}.${textToFormat.substring(6)}';
    } else {
      result =
          '${textToFormat.substring(0, 3)}.${textToFormat.substring(3, 6)}.${textToFormat.substring(6, 9)}-${textToFormat.substring(9)}';
    }

    return newValue.copyWith(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
