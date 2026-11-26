import 'package:flutter_workshop_front/core/validators/form_validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/money/money.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/currency_input_formatter.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_text_field.dart';
import 'package:provider/provider.dart';

class DeviceValuesWidget extends StatelessWidget {
  final bool isEditing;

  const DeviceValuesWidget({super.key, this.isEditing = false});

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
      child: Selector<DeviceCustomerPageController, DeviceCustomer?>(
        selector: (context, controller) => controller.deviceCustomer,
        builder: (context, deviceCustomer, child) {
          if (deviceCustomer == null) return const SizedBox.shrink();
          return Column(
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
                      semanticsIdentifier: 'deviceDetail.budgetFee',
                      headerLabel: 'Taxa de orçamento',
                      maxLines: 1,
                      errorMaxLines: 2,
                      value:
                          (deviceCustomer.budgetFee ?? Money.zero).toBrCurrency,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [CurrencyInputFormatter()],
                      readOnly: !isEditing,
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final parsedValue = Money.tryParseBr(value);
                        if (parsedValue == null) return 'Valor inválido';
                        final sumPaid = deviceCustomer.totalPaidFee;
                        if (parsedValue < sumPaid) {
                          return 'Valor mínimo: ${sumPaid.toBrCurrency}';
                        }
                        return null;
                      },
                      onSave: (value) {
                        final current = controller.deviceCustomer;
                        if (current == null) return;
                        final newDeviceCustomer = current.copyWith(
                          budgetFee: Money.tryParseBr(value) ?? Money.zero,
                        );
                        controller.updateNewDeviceCustomer(newDeviceCustomer);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      semanticsIdentifier: 'deviceDetail.serviceValue',
                      headerLabel: 'Valor do serviço',
                      maxLines: 1,
                      value: (deviceCustomer.serviceValue ?? Money.zero)
                          .toBrCurrency,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [CurrencyInputFormatter()],
                      readOnly: !isEditing,
                      validator: FormValidators.optionalMoney,
                      onSave: (value) {
                        final current = controller.deviceCustomer;
                        if (current == null) return;
                        final newDeviceCustomer = current.copyWith(
                          serviceValue: Money.tryParseBr(value) ?? Money.zero,
                        );

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
                hasBudgetFee:
                    (deviceCustomer.budgetFee ?? Money.zero).isPositive,
                computedBudgetFeeCollected:
                    deviceCustomer.computedBudgetFeeCollected,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BudgetFeeStatusWidget extends StatelessWidget {
  /// Taxa zero (ex.: revisão em garantia): não há o que coletar.
  final bool hasBudgetFee;
  final bool computedBudgetFeeCollected;

  const _BudgetFeeStatusWidget({
    required this.hasBudgetFee,
    required this.computedBudgetFeeCollected,
  });

  @override
  Widget build(BuildContext context) {
    final (
      IconData icon,
      String label,
      Color iconColor,
      Color textColor,
    ) = switch ((hasBudgetFee, computedBudgetFeeCollected)) {
      (false, _) => (
        Icons.remove_circle_outline,
        'Sem taxa',
        Colors.grey.shade500,
        Colors.grey.shade700,
      ),
      (true, true) => (
        Icons.check_circle_outline,
        'Coletada',
        Colors.green.shade600,
        Colors.green.shade700,
      ),
      (true, false) => (
        Icons.info_outline,
        'Pendente',
        Colors.orange.shade600,
        Colors.orange.shade700,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
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
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textColor,
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
