import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/double_extensions.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_device_payment.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';

class PaymentTotalsWidget extends StatelessWidget {
  final DeviceCustomer deviceCustomer;
  final List<CustomerDevicePayment> devicePayments;

  const PaymentTotalsWidget({
    super.key,
    required this.deviceCustomer,
    required this.devicePayments,
  });

  double _getTotalPayments(List<CustomerDevicePayment> devicePayments) {
    return devicePayments.fold(0, (sum, payment) => sum + payment.paymentValue);
  }

  double _getTotalValue(DeviceCustomer deviceCustomer) {
    return ((deviceCustomer.serviceValue ?? 0) -
        (deviceCustomer.laborValue ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sub total', style: textTheme.bodyMedium),
            Text(
              (deviceCustomer.serviceValue ?? 0).toBrCurrency,
              style:
                  textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Orçamento',
                style:
                    textTheme.bodyMedium?.copyWith(color: colorScheme.error)),
            Text(
              '- ${(deviceCustomer.laborValue ?? 0).toBrCurrency}',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: textTheme.titleMedium),
            Text(
              _getTotalValue(deviceCustomer).toBrCurrency,
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.attach_money, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Total pago',
                    style: textTheme.titleMedium
                        ?.copyWith(color: colorScheme.primary),
                  ),
                ],
              ),
              Text(
                _getTotalPayments(devicePayments).toBrCurrency,
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
