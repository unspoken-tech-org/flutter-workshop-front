import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/double_extensions.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_device_payment.dart';

class CustomerDevicePaymentItem extends StatelessWidget {
  final CustomerDevicePayment payment;
  const CustomerDevicePaymentItem({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Card(
      shadowColor: Colors.grey.withAlpha(60),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          spacing: 4,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data: ${payment.paymentDate}'),
            Text('Tipo: ${payment.paymentType.capitalizeFirst}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Valor: ${payment.paymentValue.toBrCurrency}'),
                Text('Pagamento: ${payment.category.capitalizeFirst}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
