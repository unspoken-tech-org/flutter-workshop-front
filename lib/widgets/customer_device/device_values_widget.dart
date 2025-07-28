import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/currency_input_formatter.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_text_field.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DeviceValuesWidget extends StatelessWidget {
  final bool isEditing;

  const DeviceValuesWidget({
    super.key,
    this.isEditing = false,
  });

  String formatValue(double value) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DeviceCustomerPageController>();
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isEditing ? Colors.blue.shade300 : const Color(0xFFE5E7EB)),
      ),
      child: Selector<DeviceCustomerPageController, DeviceCustomer>(
        selector: (context, controller) => controller.deviceCustomer,
        builder: (context, deviceCustomer, child) => Column(
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
                    controller: TextEditingController(
                        text: formatValue(deviceCustomer.laborValue ?? 0)),
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
                      final newDeviceCustomer = controller.deviceCustomer
                          .copyWith(laborValue: double.parse(normalizedValue));
                      controller.updateNewDeviceCustomer(newDeviceCustomer);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    headerLabel: 'Valor do serviço',
                    maxLines: 1,
                    controller: TextEditingController(
                        text: formatValue(deviceCustomer.serviceValue ?? 0)),
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
                      final newDeviceCustomer = controller.deviceCustomer
                          .copyWith(
                              serviceValue: double.parse(normalizedValue));
                      controller.updateNewDeviceCustomer(newDeviceCustomer);
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
                initialValue: deviceCustomer.laborValueCollected,
                enabled: isEditing,
                onSaved: (value) {
                  final newDeviceCustomer = controller.deviceCustomer.copyWith(
                    laborValueCollected: value ?? false,
                  );
                  controller.updateNewDeviceCustomer(newDeviceCustomer);
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
      ),
    );
  }
}
