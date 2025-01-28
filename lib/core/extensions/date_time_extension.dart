import 'package:intl/intl.dart';

extension DateTimeFormat on DateTime {
  String formatDate() {
    return DateFormat('dd/MM/yyyy').format(this);
  }
}
