import 'package:flutter_workshop_front/core/format/br_format.dart';
import 'package:intl/intl.dart';

extension DateTimeFormat on DateTime {
  String formatDate() {
    return BrFormat.date(this);
  }

  String formatDateTime() {
    return DateFormat('dd/MM/yyyy HH:mm').format(this);
  }

  String formatTime() {
    return DateFormat('HH:mm').format(this);
  }
}
