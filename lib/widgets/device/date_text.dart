import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/date_time_extension.dart';

class DateText extends StatelessWidget {
  final String label;
  final DateTime? date;
  const DateText({super.key, required this.label, this.date});

  @override
  Widget build(BuildContext context) {
    final d = date;
    if (d == null) return const SizedBox.shrink();
    return Row(
      spacing: 6,
      children: [
        Icon(Icons.calendar_today_outlined,
            size: 14, color: Colors.grey.shade500),
        Text('$label: ${d.formatDate()}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            )),
      ],
    );
  }
}
