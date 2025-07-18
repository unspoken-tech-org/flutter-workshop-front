import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/widgets/form_fields/urgency_switch_form_field.dart';

class UrgencySwitch extends StatelessWidget {
  final void Function(bool?)? onSaved;

  const UrgencySwitch({
    super.key,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orangeAccent,
                  size: 20,
                ),
                Text(
                  'Urgência',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            UrgencySwitchFormField(onSaved: onSaved),
          ],
        ),
        Text(
          'Marque se este serviço é urgente.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
