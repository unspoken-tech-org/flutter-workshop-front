import 'package:flutter/services.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final String newText = newValue.text;
    final String oldText = oldValue.text;

    String newDigitsOnly = newText.replaceAll(RegExp(r'\D'), '');

    final int newDigitsLength = newDigitsOnly.length;

    if (newDigitsLength > 11) {
      return TextEditingValue(
        text: oldText,
        selection: TextSelection.collapsed(offset: oldText.length),
      );
    }

    if (newDigitsLength == 0) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final StringBuffer buffer = StringBuffer();

    // (XX
    if (newDigitsLength > 0) {
      buffer.write('(');
      String dddDigits =
          newDigitsOnly.substring(0, newDigitsLength > 1 ? 2 : 1);
      buffer.write(dddDigits);
    }

    // ) XXXXX
    if (newDigitsLength > 2) {
      buffer.write(') ');

      int index = newDigitsLength > 7 ? 7 : newDigitsLength;
      String firstFiveDigits = newDigitsOnly.substring(2, index);
      buffer.write(firstFiveDigits);
    }

    // -XXXXX
    if (newDigitsLength > 7) {
      buffer.write('-');
      String lastFourDigits = newDigitsOnly.substring(7, newDigitsLength);
      buffer.write(lastFourDigits);
    }

    String formattedText = buffer.toString();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
