import 'package:flutter/material.dart';

class UrgencyRevisionChip extends StatelessWidget {
  final bool hasUrgency;
  final bool isRevision;
  const UrgencyRevisionChip(
      {super.key, required this.hasUrgency, required this.isRevision});

  String get text => isRevision ? 'Revisão' : 'Urgente';
  Color get color =>
      isRevision ? const Color.fromARGB(255, 209, 192, 40) : Colors.red;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      height: 32,
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.error_outline, color: color, size: 16),
    );
  }
}
