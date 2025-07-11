import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';

class StatusCell extends StatelessWidget {
  final StatusEnum status;
  const StatusCell({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.name,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
}
