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

  double get _totalPayments {
    return devicePayments.fold(0, (sum, payment) => sum + payment.paymentValue);
  }

  double get _totalValue {
    final serviceValue = deviceCustomer.serviceValue ?? 0;
    final laborValue = deviceCustomer.laborValue ?? 0;
    if (serviceValue == 0) return serviceValue;
    return (serviceValue - laborValue);
  }

  double get _totalToBePaid {
    return _totalValue - _totalPayments;
  }

  bool get _isPaymentPending {
    if (devicePayments.isEmpty) return true;
    return _totalToBePaid > 0;
  }

  (Color backgroundColor, Color borderColor, Color textColor, Color iconColor)
      get _totalColors {
    return _isPaymentPending
        ? (
            Colors.red.shade800,
            Colors.red.shade100,
            Colors.red.shade800,
            Colors.red.shade800
          )
        : (
            Colors.green.shade800,
            Colors.green.shade100,
            Colors.green.shade800,
            Colors.green.shade800
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
                Text('Sub total', style: textTheme.bodyMedium),
                Text(
                  (deviceCustomer.serviceValue ?? 0).toBrCurrency,
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if ((deviceCustomer.laborValue ?? 0) > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Orçamento',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: Colors.red.shade800)),
                  Text(
                    '- ${deviceCustomer.laborValue?.toBrCurrency}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            if (totalPaid > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pagamento',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: Colors.red.shade800)),
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
                          style:
                              textTheme.titleMedium?.copyWith(color: textColor),
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
