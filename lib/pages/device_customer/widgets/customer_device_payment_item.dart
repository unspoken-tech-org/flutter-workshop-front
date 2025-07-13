import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/double_extensions.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_device_payment.dart';

class CustomerDevicePaymentItem extends StatelessWidget {
  final CustomerDevicePayment payment;
  const CustomerDevicePaymentItem({super.key, required this.payment});

  Color _getPaymentTypeColor(PaymentType type) {
    switch (type) {
      case PaymentType.credito:
        return Colors.green.shade100;
      case PaymentType.debito:
        return Colors.blue.shade100;
      case PaymentType.dinheiro:
        return Colors.yellow.shade100;
      case PaymentType.pix:
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getPaymentTypeTextColor(PaymentType type) {
    switch (type) {
      case PaymentType.credito:
        return Colors.green.shade800;
      case PaymentType.debito:
        return Colors.blue.shade800;
      case PaymentType.dinheiro:
        return Colors.yellow.shade800;
      case PaymentType.pix:
        return Colors.purple.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.receipt, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        payment.paymentDate,
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPaymentTypeColor(payment.paymentType),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      payment.paymentType.displayName,
                      style: textTheme.bodySmall?.copyWith(
                        color: _getPaymentTypeTextColor(payment.paymentType),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            payment.paymentValue.toBrCurrency,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
