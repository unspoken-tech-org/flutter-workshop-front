import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/device_customer/customer_device_phones_widget.dart';
import 'package:flutter_workshop_front/pages/device_customer/customer_device_text_field.dart';
import 'package:flutter_workshop_front/pages/device_customer/device_status_chip.dart';
import 'package:flutter_workshop_front/pages/device_customer/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/pages/device_customer/urgency_revision_chip.dart';
import 'package:flutter_workshop_front/widgets/customer_device/device_customer_save_button.dart';

class CustomerDeviceInfosWidget extends StatelessWidget {
  const CustomerDeviceInfosWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceCustomerController.of(context);
    var width = MediaQuery.of(context).size.width;

    return ValueListenableBuilder(
      valueListenable: controller.newDeviceCustomer,
      builder: (context, value, child) {
        var deviceCustomer = value;
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: width * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID do aparelho # ${deviceCustomer.deviceId}'),
                          const SizedBox(height: 8),
                          Text('Cliente: ${deviceCustomer.customerName}'),
                          CustomerDevicePhonesWidget(
                            phones: deviceCustomer.customerPhones,
                          ),
                          const SizedBox(height: 16),
                          Text(
                              '${deviceCustomer.typeName} ${deviceCustomer.brandName} | ${deviceCustomer.modelName}'),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (deviceCustomer.hasUrgency ||
                              deviceCustomer.isRevision) ...[
                            UrgencyRevisionChip(
                                hasUrgency: deviceCustomer.hasUrgency,
                                isRevision: deviceCustomer.isRevision),
                            const SizedBox(height: 4),
                          ],
                          DeviceStatusChip(status: deviceCustomer.deviceStatus),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cores: ${deviceCustomer.deviceColors.join(', ')}',
                  ),
                  const SizedBox(height: 8),
                  Text('Data de entrada: ${deviceCustomer.entryDate}'),
                  const SizedBox(height: 8),
                  Text('Data de saída: ${deviceCustomer.departureDate}'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Problema:'),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 100,
                              maxWidth: width * 0.2,
                            ),
                            child: CustomerDeviceTextField(
                              initialValue: deviceCustomer.problem,
                              onUpdate: (value) {
                                controller.updateNewDeviceCustomer(
                                    deviceCustomer.copyWith(problem: value));
                              },
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Orçamento:'),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 100,
                              maxWidth: width * 0.2,
                            ),
                            child: CustomerDeviceTextField(
                              initialValue: deviceCustomer.budget,
                              onUpdate: (value) {
                                controller.updateNewDeviceCustomer(
                                    deviceCustomer.copyWith(budget: value));
                              },
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Observações:'),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 100,
                              maxWidth: width * 0.2,
                            ),
                            child: CustomerDeviceTextField(
                              initialValue: deviceCustomer.observation,
                              onUpdate: (value) {
                                controller.updateNewDeviceCustomer(
                                    deviceCustomer.copyWith(
                                        observation: value));
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [DeviceCustomerSaveButton()],
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
