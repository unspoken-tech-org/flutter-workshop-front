import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/widgets/device/date_text.dart';
import 'package:flutter_workshop_front/widgets/device/revision_urgency_chip.dart';
import 'package:flutter_workshop_front/widgets/hoverable_card.dart';
import 'package:flutter_workshop_front/widgets/shared/status_cell.dart';

class FilteredDeviceCard extends StatelessWidget {
  final DeviceDataTable device;
  final VoidCallback onTap;
  const FilteredDeviceCard({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HoverableCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Flexible(
            child: Row(
              children: [
                Row(
                  spacing: 16,
                  children: [
                    Text('#${device.deviceId}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    RevisionUrgencyChip(
                      isUrgent: device.hasUrgency,
                      isRevision: device.hasRevision,
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Row(
                      spacing: 4,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 16),
                        Text(device.customerName.capitalizeAllWords,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Text(
                        '${device.type.capitalizeAllWords} - ${device.brand.capitalizeAllWords} ${device.model.capitalizeAllWords}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                    Row(
                      spacing: 18,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DateText(label: 'Entrada', date: device.entryDate),
                        DateText(label: 'Saída', date: device.departureDate),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          StatusCell(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
            status: device.status,
          )
        ],
      ),
    );
  }
}
