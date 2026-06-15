import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/double_extensions.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/currency_input_formatter.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_device_payment.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_text_field.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DeviceValuesWidget extends StatelessWidget {
  final bool isEditing;

  const DeviceValuesWidget({super.key, this.isEditing = false});

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
          color: isEditing ? Colors.blue.shade300 : const Color(0xFFE5E7EB),
        ),
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
                    headerLabel: 'Taxa de orçamento',
                    maxLines: 1,
                    errorMaxLines: 2,
                    controller: TextEditingController(
                      text: formatValue(deviceCustomer.budgetFee ?? 0),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [CurrencyInputFormatter()],
                    readOnly: !isEditing,
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      final parsedValue =
                          double.tryParse(
                            value
                                .replaceAll('R\$', '')
                                .replaceAll('.', '')
                                .replaceAll(',', '.'),
                          ) ??
                          0;
                      final sumPaid = deviceCustomer.payments
                          .where((p) => p.category == PaymentCategory.budgetFee)
                          .fold(0.0, (sum, p) => sum + p.paymentValue);
                      if (parsedValue < sumPaid) {
                        return 'Valor mínimo: ${sumPaid.toBrCurrency}';
                      }
                      return null;
                    },
                    onSave: (value) {
                      String normalizedValue =
                          value?.replaceAll('R\$', '').replaceAll(',', '.') ??
                          '0';
                      final newDeviceCustomer = controller.deviceCustomer
                          .copyWith(budgetFee: double.parse(normalizedValue));
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
                      text: formatValue(deviceCustomer.serviceValue ?? 0),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [CurrencyInputFormatter()],
                    readOnly: !isEditing,
                    onSave: (value) {
                      final newDeviceCustomer = controller.deviceCustomer
                          .copyWith(serviceValue: value?.fromCurrency());

                      controller.updateNewDeviceCustomer(newDeviceCustomer);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE5E7EB), height: 1),
            const SizedBox(height: 16),
            _BudgetFeeStatusWidget(
              computedBudgetFeeCollected:
                  deviceCustomer.computedBudgetFeeCollected,
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetFeeStatusWidget extends StatelessWidget {
  final bool computedBudgetFeeCollected;

  const _BudgetFeeStatusWidget({required this.computedBudgetFeeCollected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            computedBudgetFeeCollected
                ? Icons.check_circle_outline
                : Icons.info_outline,
            size: 20,
            color: computedBudgetFeeCollected
                ? Colors.green.shade600
                : Colors.orange.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Taxa de orçamento',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  computedBudgetFeeCollected ? 'Coletada' : 'Pendente',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: computedBudgetFeeCollected
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
