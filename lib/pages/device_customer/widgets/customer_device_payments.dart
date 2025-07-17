import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_device_payment.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/pages/device_customer/widgets/customer_device_payment_item.dart';
import 'package:flutter_workshop_front/pages/device_customer/widgets/empty_payments_widget.dart';
import 'package:flutter_workshop_front/pages/device_customer/widgets/payment_totals_widget.dart';
import 'package:flutter_workshop_front/pages/device_customer/widgets/dialogs/add_new_payment_dialog.dart';

class CustomerDevicePayments extends StatefulWidget {
  const CustomerDevicePayments({super.key});

  @override
  State<CustomerDevicePayments> createState() => _CustomerDevicePaymentsState();
}

class _CustomerDevicePaymentsState extends State<CustomerDevicePayments> {
  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceCustomerController.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ValueListenableBuilder<DeviceCustomer>(
          valueListenable: controller.deviceCustomer,
          builder: (context, deviceCustomer, child) {
            final List<CustomerDevicePayment> devicePayments =
                deviceCustomer.payments;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final showLabel = constraints.maxWidth > 300;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.credit_card),
                            const SizedBox(width: 8),
                            Text(
                              'Pagamentos',
                              style: textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        OutlinedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  InheritedDeviceCustomerController(
                                controller: controller,
                                child: const AddNewPaymentDialog(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            alignment: Alignment.center,
                            iconColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: const BorderSide(color: Colors.black),
                            ),
                          ),
                          child: Row(
                            spacing: 6,
                            children: [
                              if (showLabel)
                                const Text(
                                  'Adicionar',
                                  style: TextStyle(color: Colors.black),
                                ),
                              const Icon(Icons.add, size: 16),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                if (devicePayments.isNotEmpty)
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: devicePayments.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        return CustomerDevicePaymentItem(
                          payment: devicePayments[index],
                        );
                      },
                    ),
                  )
                else
                  const Center(child: EmptyPaymentsWidget()),
                const SizedBox(height: 24),
                PaymentTotalsWidget(
                  deviceCustomer: deviceCustomer,
                  devicePayments: devicePayments,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
