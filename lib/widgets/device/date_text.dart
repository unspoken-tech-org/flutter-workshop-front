import 'package:flutter/material.dart';

class DateText extends StatelessWidget {
  final String label;
  final String? date;
  const DateText({super.key, required this.label, this.date});

  @override
  Widget build(BuildContext context) {
    if (date == null) return const SizedBox.shrink();
    return Row(
      spacing: 6,
      children: [
        Icon(Icons.calendar_today_outlined,
            size: 14, color: Colors.grey.shade500),
        Text('$label: $date',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            )),
      ],
    );
  }
}
