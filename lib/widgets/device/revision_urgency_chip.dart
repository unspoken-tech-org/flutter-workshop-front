import 'package:flutter/material.dart';

class RevisionUrgencyChip extends StatelessWidget {
  final bool isUrgent;
  final bool isRevision;

  const RevisionUrgencyChip({
    super.key,
    required this.isUrgent,
    required this.isRevision,
  });

  @override
  Widget build(BuildContext context) {
    if (!isUrgent && !isRevision) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red : Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isUrgent ? 'Urgente' : 'Revisão',
        style: TextStyle(
          color: isUrgent ? Colors.white : Colors.deepPurple.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
