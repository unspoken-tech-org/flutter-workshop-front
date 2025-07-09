import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/models/colors/color_model.dart';
import 'package:flutter_workshop_front/pages/device/controller/inherited_device_register_controller.dart';

class SelectedColorsFormField extends StatelessWidget {
  const SelectedColorsFormField({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceRegisterController.of(context);
    return ValueListenableBuilder<List<ColorModel>>(
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
                errorText: state.errorText,
                labelText: 'Cores selecionadas',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(8.0),
              ).applyDefaults(Theme.of(context).inputDecorationTheme),
              isEmpty: selectedColors.isEmpty,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: selectedColors
                      .map(
                        (color) => Chip(
                          backgroundColor: Colors.white10,
                          label: Text(color.color.capitalizeFirst),
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
    );
  }
}
