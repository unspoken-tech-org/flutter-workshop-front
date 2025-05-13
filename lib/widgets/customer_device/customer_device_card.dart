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
      child: Card(
        color: Colors.white,
        shadowColor: Colors.grey.withOpacity(0.5),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Id: ${device.deviceId}'),
                  const SizedBox(height: 8),
                  Text(device.typeBrandModel),
                  const SizedBox(height: 50),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Data de entrada: ${device.entryDate}'),
                      if (device.departureDate != null) ...[
                        const SizedBox(height: 6),
                        Text('Data de saída: ${device.departureDate!}'),
                      ],
                    ],
                  )
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
