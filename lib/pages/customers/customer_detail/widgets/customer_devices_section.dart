import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/controllers/customer_detail_controller.dart';
import 'package:flutter_workshop_front/widgets/customer_device/customer_devices_list.dart';
import 'package:flutter_workshop_front/widgets/shared/empty_list_widget.dart';
import 'package:provider/provider.dart';

class CustomerDevicesSection extends StatelessWidget {
  const CustomerDevicesSection({super.key, required this.customerId});

  final int customerId;

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerDetailController>(
      builder: (context, controller, _) {
        final customer = controller.customer;
        if (customer == null) return const SizedBox.shrink();
        if (controller.isEditing) return const SizedBox.shrink();
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
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
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  SizedBox(
                    height: 500,
                    child: Visibility(
                      visible: customer.customerDevices.isNotEmpty,
                      replacement: const EmptyListWidget(
                        message: 'Nenhum aparelho encontrado',
                      ),
                      child: CustomerDevicesList(
                        customerDevices: customer.customerDevices,
                        onTap: (id) {
                          WsNavigator.pushDeviceDetails(context, id).then((_) {
                            controller.fetchCustomer(customerId);
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
