import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_device_payment.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/pages/device_customer/widgets/customer_device_payment_item.dart';
import 'package:flutter_workshop_front/pages/device_customer/widgets/empty_payments_widget.dart';
import 'package:flutter_workshop_front/pages/device_customer/widgets/payment_totals_widget.dart';

class CustomerDevicePayments extends StatefulWidget {
  const CustomerDevicePayments({super.key});

  @override
  State<CustomerDevicePayments> createState() => _CustomerDevicePaymentsState();
}

class _CustomerDevicePaymentsState extends State<CustomerDevicePayments> {
  late final ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceCustomerController.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: ValueListenableBuilder(
        valueListenable: controller.newDeviceCustomer,
        builder: (context, value, child) {
          final DeviceCustomer deviceCustomer = value;
          final List<CustomerDevicePayment> devicePayments =
              deviceCustomer.payments;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      const Text(
                        'Pagamentos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Visibility(
                          visible: devicePayments.isNotEmpty,
                          replacement: const Center(
                            child: EmptyPaymentsWidget(),
                          ),
                          child: Scrollbar(
                            controller: scrollController,
                            thumbVisibility: true,
                            child: ListView.separated(
                              controller: scrollController,
                              itemCount: devicePayments.length,
                              separatorBuilder: (context, index) {
                                return const SizedBox(height: 10);
                              },
                              itemBuilder: (context, index) {
                                return CustomerDevicePaymentItem(
                                  payment: devicePayments[index],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PaymentTotalsWidget(
                deviceCustomer: deviceCustomer,
                devicePayments: devicePayments,
              ),
            ],
          );
        },
      ),
    );
  }
}
