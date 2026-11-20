import 'package:intl/intl.dart';

class Money implements Comparable<Money> {
  final int cents;

  const Money.fromCents(this.cents);

  static const Money zero = Money.fromCents(0);

  factory Money.fromReais(num value) {
    if (!value.isFinite) {
      throw FormatException('Invalid money value: $value');
    }
    return Money.fromCents((value * 100).round());
  }

  factory Money.fromJson(dynamic value) {
    if (value is Money) return value;
    if (value is num) return Money.fromReais(value);
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.contains(',') || trimmed.contains('R\$')) {
        final brParsed = Money.tryParseBr(trimmed);
        if (brParsed != null) return brParsed;
      } else {
        final numParsed = double.tryParse(trimmed);
        if (numParsed != null && numParsed.isFinite) {
          return Money.fromReais(numParsed);
        }
      }
    }
    throw FormatException('Invalid money value: $value');
  }

  static Money? tryParseBr(String? text) {
    if (text == null) return null;

    var cleaned = text
        .replaceAll(RegExp(r'[\s\u00A0]+'), '')
        .replaceAll('R\$', '');
    if (cleaned.isEmpty) return null;

    var isNegative = false;
    if (cleaned.startsWith('-')) {
      isNegative = true;
      cleaned = cleaned.substring(1);
    } else if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    if (cleaned.isEmpty) return null;
    if (!RegExp(r'^[0-9.,]+$').hasMatch(cleaned)) return null;

    final commaCount = ','.allMatches(cleaned).length;
    if (commaCount > 1) return null;

    final intPartPattern = RegExp(r'^(\d+|\d{1,3}(\.\d{3})+)$');
    int totalCents;

    if (commaCount == 1) {
      final parts = cleaned.split(',');
      final intPart = parts[0];
      final decPart = parts[1];

      if (!intPartPattern.hasMatch(intPart)) return null;
      if (!RegExp(r'^\d{1,2}$').hasMatch(decPart)) return null;

      final reais = int.tryParse(intPart.replaceAll('.', ''));
      final centDigits = int.tryParse(decPart.padRight(2, '0'));
      if (reais == null || centDigits == null) return null;

      totalCents = reais * 100 + centDigits;
    } else {
      if (!intPartPattern.hasMatch(cleaned)) return null;
      final reais = int.tryParse(cleaned.replaceAll('.', ''));
      if (reais == null) return null;

      totalCents = reais * 100;
    }

    return Money.fromCents(isNegative ? -totalCents : totalCents);
  }

  double toJson() => cents / 100;

  String get toBrCurrency =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(cents / 100);

  bool get isZero => cents == 0;
  bool get isPositive => cents > 0;
  bool get isNegative => cents < 0;

  Money operator +(Money other) => Money.fromCents(cents + other.cents);
  Money operator -(Money other) => Money.fromCents(cents - other.cents);

  bool operator <(Money other) => cents < other.cents;
  bool operator <=(Money other) => cents <= other.cents;
  bool operator >(Money other) => cents > other.cents;
  bool operator >=(Money other) => cents >= other.cents;

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Money && other.cents == cents);

  @override
  int get hashCode => cents.hashCode;

  @override
  String toString() => toBrCurrency;
}
