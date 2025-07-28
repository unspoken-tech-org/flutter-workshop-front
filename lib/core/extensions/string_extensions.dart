extension StringExtension on String {
  String get capitalizeFirst {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  String get capitalizeAll {
    if (isEmpty) return this;
    return toUpperCase();
  }

  String get capitalizeAllWords {
    if (isEmpty) return this;
    return split(' ').map((e) => e.capitalizeFirst).join(' ');
  }

  double fromCurrency() {
    final value = replaceAll(RegExp(r'[R$.]'), '').replaceAll(',', '.');
    return double.tryParse(value) ?? 0;
  }
}
