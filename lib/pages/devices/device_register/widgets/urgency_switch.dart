import 'package:flutter/material.dart';

class UrgencySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const UrgencySwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(value ? Icons.flash_on : Icons.flash_off,
            color: value ? Colors.red : Colors.grey),
        const SizedBox(width: 16),
        const Text('Urgência'),
        const Spacer(),
        InkWell(
          onTap: () => onChanged(!value),
          hoverColor: Colors.transparent,
          child: Switch(
            hoverColor: Colors.transparent,
            activeColor: Colors.red,
            inactiveTrackColor: Colors.grey,
            value: value,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
