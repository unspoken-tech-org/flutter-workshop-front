import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer_device/minified_customer_device.dart';
import 'package:flutter_workshop_front/widgets/customer_device/customer_device_text_field.dart';
import 'package:flutter_workshop_front/widgets/customer_device/urgency_revision_chip.dart';
import 'package:flutter_workshop_front/widgets/shared/status_cell.dart';

class CustomerDeviceCard extends StatelessWidget {
  final MinifiedCustomerDevice device;
  final void Function(int) onTap;
  const CustomerDeviceCard(
      {super.key, required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTap(device.deviceId);
      },
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              offset: Offset(0, 1),
              blurRadius: 3.0,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              offset: Offset(0, 1),
              blurRadius: 2.0,
              spreadRadius: -1.0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 12,
                children: [
                  Text('Id: ${device.deviceId}'),
                  Text(device.typeBrandModel),
                  Text('Data de entrada: ${device.entryDate}'),
                  if (device.departureDate != null) ...[
                    Text('Data de saída: ${device.departureDate!}'),
                  ]
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      if (device.hasUrgency || device.revision) ...[
                        UrgencyRevisionChip(
                          hasUrgency: device.hasUrgency,
                          isRevision: device.revision,
                        ),
                        const SizedBox(width: 20),
                      ],
                      StatusCell(status: device.deviceStatus),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 300,
                    ),
                    child: CustomerDeviceTextField(
                      initialValue: device.problem,
                      enabled: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
