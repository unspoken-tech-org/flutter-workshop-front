import 'package:flutter_workshop_front/core/format/br_format.dart';
import 'package:flutter/services.dart';
import 'package:flutter_workshop_front/core/money/money.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final digitsOnly = BrFormat.digitsOnly(newValue.text);
    if (digitsOnly.isEmpty) {
      return const TextEditingValue();
    }

    final cents = int.tryParse(digitsOnly);
    if (cents == null) {
      return oldValue;
    }

    final newString = Money.fromCents(cents).toBrCurrency.trim();

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
