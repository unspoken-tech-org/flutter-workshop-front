import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';

class StatusCell extends StatelessWidget {
  final StatusEnum status;
  final EdgeInsets padding;
  const StatusCell({
    super.key,
    required this.status,
    this.padding = const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
  });

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, textColor) = status.colors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
