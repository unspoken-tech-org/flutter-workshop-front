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
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sub total',
                style: TextStyle(color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  (deviceCustomer.serviceValue ?? 0).toBrCurrency,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              if (deviceCustomer.laborValue != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Orçamento',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '- ${(deviceCustomer.laborValue ?? 0).toBrCurrency}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                'Total',
                style: TextStyle(color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  _getTotalValue(deviceCustomer).toBrCurrency,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Total pago',
                  style: TextStyle(color: Colors.white),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    _getTotalPayments(devicePayments).toBrCurrency,
                    style: const TextStyle(color: Colors.white),
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
