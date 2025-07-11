import 'package:flutter/material.dart';

class RevisionChip extends StatelessWidget {
  final bool revision;
  final bool showTooltip;
  final VoidCallback? onTap;

  const RevisionChip({
    super.key,
    required this.revision,
    this.showTooltip = true,
    this.onTap,
  });

  Color get color => revision ? Colors.red : Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: showTooltip
          ? (revision ? 'Aparelho em Revisão' : 'Não está em revisão')
          : null,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          height: 32,
          decoration: BoxDecoration(
            color: color.withAlpha(40),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.history, color: color, size: 16),
        ),
      ),
    );
  }
}
