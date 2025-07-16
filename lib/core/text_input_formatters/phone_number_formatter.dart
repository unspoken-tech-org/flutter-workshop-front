import 'package:flutter/services.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;

    final newDigitsOnly = newText.replaceAll(RegExp(r'\D'), '');
    final newDigitsLength = newDigitsOnly.length;

    if (newDigitsLength > 11) {
      return oldValue;
    }

    if (newDigitsLength == 0) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final buffer = StringBuffer();
    final isElevenDigits = newDigitsLength > 10;

    buffer.write('(');
    buffer.write(
      newDigitsOnly.substring(0, newDigitsLength > 2 ? 2 : newDigitsLength),
    );
    // (XX
    if (newDigitsLength > 2) {
      buffer.write(') ');

      // ) XXXXX
      if (isElevenDigits) {
        final firstPart = newDigitsOnly.substring(2, 7);
        buffer.write(firstPart);
        buffer.write('-');
        buffer.write(newDigitsOnly.substring(7));
      } else {
        // ) XXXX
        final firstPartLength = newDigitsLength > 6 ? 4 : newDigitsLength - 2;
        final firstPart = newDigitsOnly.substring(2, 2 + firstPartLength);
        buffer.write(firstPart);

        if (newDigitsLength > 6) {
          buffer.write('-');
          buffer.write(newDigitsOnly.substring(6));
        }
      }
    }

    final formattedText = buffer.toString();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
