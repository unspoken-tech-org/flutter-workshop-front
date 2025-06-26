import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/phone_number_formatter.dart';

class SecondaryPhoneFields extends StatelessWidget {
  /// [controllers] is a list of maps with the following structure:
  /// {
  ///   'name': TextEditingController,
  ///   'number': TextEditingController,
  /// }
  final List<Map<String, dynamic>> controllers;

  /// [onRemoveController] is a function that removes a controller from the list
  final Function(int) onRemoveController;

  /// [isEditing] is a boolean to control the interactivity of the fields
  final bool isEditing;

  const SecondaryPhoneFields({
    super.key,
    required this.controllers,
    required this.onRemoveController,
    this.isEditing = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(controllers.length, (i) {
        var phoneMaskFormatter = PhoneNumberFormatter();

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Flexible(
                flex: 2,
                child: TextFormField(
                  controller: controllers[i]['name'] as TextEditingController,
                  readOnly: !isEditing,
                  decoration: const InputDecoration(
                    labelText: 'Nome secundário (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 1,
                child: TextFormField(
                  controller: controllers[i]['number'] as TextEditingController,
                  readOnly: !isEditing,
                  decoration: InputDecoration(
                    labelText: 'Telefone ${i + 2}',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [phoneMaskFormatter],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o telefone';
                    }
                    final int digitCount =
                        value.replaceAll(RegExp(r'\D'), '').length;
                    if (digitCount < 10) {
                      return 'Telefone incompleto';
                    }
                    return null;
                  },
                ),
              ),
              if (isEditing) ...[
                const SizedBox(width: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      style: IconButton.styleFrom(
                        iconSize: 32,
                      ),
                      onPressed: () => onRemoveController(i),
                    ),
                  ],
                )
              ]
            ],
          ),
        );
      }),
    );
  }
}
