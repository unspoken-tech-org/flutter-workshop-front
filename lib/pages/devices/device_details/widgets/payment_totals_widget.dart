import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/money/money.dart';
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

  Money get _totalPayments {
    return devicePayments.fold(
      Money.zero,
      (sum, payment) => sum + payment.paymentValue,
    );
  }

  Money get _totalValue {
    return deviceCustomer.serviceValue ?? Money.zero;
  }

  Money get _totalToBePaid {
    return _totalValue - _totalPayments;
  }

  bool get _isPaymentPending {
    if (devicePayments.isEmpty) return true;
    return _totalToBePaid.isPositive;
  }

  (Color backgroundColor, Color borderColor, Color textColor, Color iconColor)
  get _totalColors {
    return _isPaymentPending
        ? (
            Colors.red.shade800,
            Colors.red.shade100,
            Colors.red.shade800,
            Colors.red.shade800,
          )
        : (
            Colors.green.shade800,
            Colors.green.shade100,
            Colors.green.shade800,
            Colors.green.shade800,
          );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final totalPaid = _totalPayments;
    final totalToBePaid = _totalToBePaid;
    final isPaymentPending = _isPaymentPending;
    final (backgroundColor, borderColor, textColor, iconColor) = _totalColors;

    return Column(
      spacing: 16,
      children: [
        const Divider(),
        Column(
          spacing: 8,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total a ser pago', style: textTheme.bodyMedium),
                Text(
                  (deviceCustomer.serviceValue ?? Money.zero).toBrCurrency,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (totalPaid.isPositive)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total pago',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.red.shade800,
                    ),
                  ),
                  Text(
                    '- ${totalPaid.toBrCurrency}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const Divider(),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor.withValues(alpha: 0.2)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showLabel = constraints.maxWidth > 250;

              return Row(
                mainAxisAlignment: (showLabel && isPaymentPending)
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.center,
                children: [
                  if (showLabel)
                    Row(
                      spacing: 8,
                      children: [
                        Icon(
                          isPaymentPending
                              ? Icons.attach_money
                              : Icons.check_circle,
                          color: iconColor,
                        ),
                        Text(
                          isPaymentPending
                              ? 'Valor a ser pago'
                              : 'Valor total pago',
                          style: textTheme.titleMedium?.copyWith(
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  if (isPaymentPending)
                    Text(
                      totalToBePaid.toBrCurrency,
                      style: textTheme.titleLarge?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
