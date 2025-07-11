import 'package:flutter/material.dart';

class UrgencyChip extends StatelessWidget {
  final bool hasUrgency;
  final bool showTooltip;
  final VoidCallback? onTap;

  const UrgencyChip({
    super.key,
    required this.hasUrgency,
    this.showTooltip = true,
    this.onTap,
  });

  Color get color => hasUrgency ? Colors.red : Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: showTooltip ? (hasUrgency ? 'Urgente' : 'Não urgente') : null,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          height: 32,
          decoration: BoxDecoration(
            color: color.withAlpha(40),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
              hasUrgency
                  ? Icons.hourglass_bottom_outlined
                  : Icons.hourglass_disabled,
              color: color,
              size: 16),
        ),
      ),
    );
  }
}
