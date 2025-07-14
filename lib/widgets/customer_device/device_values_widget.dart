import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/currency_input_formatter.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/widgets/customer_device/form_fields/custom_text_field.dart';
import 'package:intl/intl.dart';

class DeviceValuesWidget extends StatelessWidget {
  final double laborValue;
  final double serviceValue;
  final bool laborValueCollected;
  final bool isEditing;

  const DeviceValuesWidget({
    super.key,
    required this.laborValue,
    required this.serviceValue,
    required this.laborValueCollected,
    this.isEditing = false,
  });

  String formatValue(double value) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceCustomerController.of(context);
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isEditing ? Colors.blue.shade300 : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.attach_money),
              SizedBox(width: 8),
              Text(
                'Valores',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextField(
                  headerLabel: 'Valor do orçamento',
                  maxLines: 1,
                  controller:
                      TextEditingController(text: formatValue(laborValue)),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    CurrencyInputFormatter(),
                  ],
                  readOnly: !isEditing,
                  onSave: (value) {
                    String normalizedValue =
                        value?.replaceAll('R\$', '').replaceAll(',', '.') ??
                            '0';
                    controller.updateNewDeviceCustomer(controller
                        .deviceCustomer.value
                        .copyWith(laborValue: double.parse(normalizedValue)));
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  headerLabel: 'Valor do serviço',
                  maxLines: 1,
                  controller:
                      TextEditingController(text: formatValue(serviceValue)),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    CurrencyInputFormatter(),
                  ],
                  readOnly: !isEditing,
                  onSave: (value) {
                    String normalizedValue =
                        value?.replaceAll('R\$', '').replaceAll(',', '.') ??
                            '0';
                    controller.updateNewDeviceCustomer(controller
                        .deviceCustomer.value
                        .copyWith(serviceValue: double.parse(normalizedValue)));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(
            color: Color(0xFFE5E7EB),
            height: 1,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FormField<bool>(
              initialValue: laborValueCollected,
              enabled: isEditing,
              onSaved: (value) {
                controller.updateNewDeviceCustomer(controller
                    .deviceCustomer.value
                    .copyWith(laborValueCollected: value ?? false));
              },
              builder: (state) => CheckboxListTile(
                title: const Text('Orçamento coletado'),
                enabled: isEditing,
                value: state.value,
                onChanged: (value) => state.didChange(value ?? false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
