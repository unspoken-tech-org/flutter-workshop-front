import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/date_time_extension.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_device_payment.dart';
import 'package:flutter_workshop_front/widgets/hoverable_card.dart';

class CustomerDevicePaymentItem extends StatelessWidget {
  final CustomerDevicePayment payment;
  const CustomerDevicePaymentItem({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final isBudgetFee = payment.category == PaymentCategory.budgetFee;

    return HoverableCard(
      padding: const EdgeInsets.all(12),
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 260;

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Row(
                  spacing: 12,
                  children: [
                    _PaymentIcon(isBudgetFee: isBudgetFee),
                    Expanded(
                      child: _PaymentDateTime(paymentDate: payment.paymentDate),
                    ),
                  ],
                ),
                _PaymentBadges(payment: payment, isBudgetFee: isBudgetFee),
                Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: _PaymentValue(payment: payment),
                  ),
                ),
              ],
            );
          }

          return Row(
            spacing: 12,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [_PaymentIcon(isBudgetFee: isBudgetFee)],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    _PaymentDateTime(paymentDate: payment.paymentDate),
                    _PaymentBadges(payment: payment, isBudgetFee: isBudgetFee),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.45,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: _PaymentValue(payment: payment),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PaymentIcon extends StatelessWidget {
  final bool isBudgetFee;

  const _PaymentIcon({required this.isBudgetFee});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isBudgetFee
            ? Colors.orange.shade50
            : colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        isBudgetFee ? Icons.receipt_long : Icons.receipt,
        color: isBudgetFee ? Colors.orange.shade700 : colorScheme.primary,
        size: 18,
      ),
    );
  }
}

class _PaymentDateTime extends StatelessWidget {
  final DateTime paymentDate;

  const _PaymentDateTime({required this.paymentDate});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        Row(
          spacing: 4,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 11),
            Flexible(
              child: Text(
                paymentDate.formatDate(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        Text(
          paymentDate.formatTime(),
          style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _PaymentBadges extends StatelessWidget {
  final CustomerDevicePayment payment;
  final bool isBudgetFee;

  const _PaymentBadges({required this.payment, required this.isBudgetFee});

  (Color, Color) _getPaymentTypeColors(PaymentType type) {
    switch (type) {
      case PaymentType.credito:
        return (Colors.green.shade800, Colors.green.shade100);
      case PaymentType.debito:
        return (Colors.blue.shade800, Colors.blue.shade100);
      case PaymentType.dinheiro:
        return (Colors.yellow.shade800, Colors.yellow.shade100);
      case PaymentType.pix:
        return (Colors.purple.shade800, Colors.purple.shade100);
      default:
        return (Colors.grey.shade800, Colors.grey.shade200);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (paymentTextColor, paymentBackgroundColor) = _getPaymentTypeColors(
      payment.paymentType,
    );

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isBudgetFee ? Colors.orange.shade100 : Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isBudgetFee
                  ? Colors.orange.shade300
                  : Colors.indigo.shade200,
            ),
          ),
          child: Text(
            isBudgetFee ? 'Taxa' : 'Serviço',
            style: textTheme.bodySmall?.copyWith(
              color: isBudgetFee
                  ? Colors.orange.shade800
                  : Colors.indigo.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: paymentBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            payment.paymentType.displayName,
            style: textTheme.bodySmall?.copyWith(
              color: paymentTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (payment.receivedBy != null && payment.receivedBy!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person, size: 12, color: Colors.teal.shade700),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    payment.receivedBy!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.teal.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PaymentValue extends StatelessWidget {
  final CustomerDevicePayment payment;

  const _PaymentValue({required this.payment});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text(
      payment.paymentValue.toBrCurrency,
      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
