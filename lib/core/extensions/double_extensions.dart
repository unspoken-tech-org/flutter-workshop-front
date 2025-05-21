import 'package:intl/intl.dart';

extension DoubleExtensions on double {
  String get toBrCurrency =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(this);
}
