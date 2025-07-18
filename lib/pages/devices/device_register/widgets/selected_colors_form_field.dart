import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/models/colors/color_model.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/controller/inherited_device_register_controller.dart';

class SelectedColorsFormField extends StatelessWidget {
  final String? headerLabel;
  const SelectedColorsFormField({super.key, this.headerLabel});

  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceRegisterController.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headerLabel != null) ...[
          Text(
            headerLabel!,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        ValueListenableBuilder<List<ColorModel>>(
          valueListenable: controller.selectedColors,
          builder: (context, selectedColors, _) {
            return FormField<List<ColorModel>>(
              initialValue: controller.selectedColors.value,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Selecione ao menos uma cor no campo ao lado';
                }
                return null;
              },
              builder: (state) {
                return InputDecorator(
                  decoration: InputDecoration(
                    hintText: 'Selecione ao menos uma cor no campo ao lado',
                    hintStyle:
                        const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 12.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide:
                          BorderSide(color: Colors.blue.shade300, width: 1.5),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  isEmpty: selectedColors.isEmpty,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: selectedColors
                          .map(
                            (color) => Chip(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              label: Text(
                                color.color.capitalizeFirst,
                                style: const TextStyle(
                                  color: Color(0xFF374151),
                                  fontSize: 14,
                                ),
                              ),
                              onDeleted: () {
                                controller.removeColor(color);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
