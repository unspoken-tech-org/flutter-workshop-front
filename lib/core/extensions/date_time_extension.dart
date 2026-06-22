import 'package:intl/intl.dart';

extension DateTimeFormat on DateTime {
  String formatDate() {
    return DateFormat('dd/MM/yyyy').format(this);
  }

  String formatDateTime() {
    return DateFormat('dd/MM/yyyy HH:mm').format(this);
  }

  String formatTime() {
    return DateFormat('HH:mm').format(this);
  }
}
