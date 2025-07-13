import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer_device/minified_customer_device.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/widgets/hoverable_card.dart';
import 'package:flutter_workshop_front/widgets/customer_device/revision_chip.dart';
import 'package:flutter_workshop_front/widgets/customer_device/urgency_chip.dart';
import 'package:flutter_workshop_front/widgets/shared/status_cell.dart';

class CustomerDeviceCard extends StatelessWidget {
  final MinifiedCustomerDevice device;
  final void Function(int) onTap;

  const CustomerDeviceCard({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HoverableCard(
      onTap: () => onTap(device.deviceId),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OtherDeviceHeaderCard(
              id: device.deviceId,
              status: device.deviceStatus,
              hasUrgency: device.hasUrgency,
              revision: device.revision,
            ),
            const SizedBox(height: 16),
            _DeviceNameAndProblem(
              deviceName: device.typeBrandModel,
              problem: device.problem,
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade900, thickness: 0.1),
            const SizedBox(height: 12),
            _DeviceInAndOutDate(
              inDate: device.entryDate,
              outDate: device.departureDate,
            ),
          ],
        ),
      ),
    );
  }
}

class _OtherDeviceHeaderCard extends StatelessWidget {
  final int id;
  final StatusEnum status;
  final bool hasUrgency;
  final bool revision;

  const _OtherDeviceHeaderCard({
    required this.id,
    required this.status,
    required this.hasUrgency,
    required this.revision,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 22, color: Colors.black54),
            children: [
              const TextSpan(text: '# '),
              TextSpan(
                text: 'Id: $id',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        StatusCell(status: status),
        const Spacer(),
        UrgencyChip(hasUrgency: hasUrgency),
        const SizedBox(width: 8),
        RevisionChip(revision: revision)
      ],
    );
  }
}

class _DeviceNameAndProblem extends StatelessWidget {
  final String deviceName;
  final String problem;

  const _DeviceNameAndProblem({
    required this.deviceName,
    required this.problem,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ColumnInfoCell(
              icon: Icons.microwave_outlined,
              title: 'Aparelho:',
              value: deviceName),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ColumnInfoCell(
            icon: Icons.watch_later_outlined,
            title: 'Problema:',
            value: problem,
          ),
        ),
      ],
    );
  }
}

class _DeviceInAndOutDate extends StatelessWidget {
  final String inDate;
  final String? outDate;

  const _DeviceInAndOutDate({
    required this.inDate,
    required this.outDate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Expanded(
          child: _RowInfoCell(
              icon: Icons.calendar_today_outlined,
              title: 'Data de entrada:',
              value: inDate),
        ),
        if (outDate != null)
          Expanded(
            child: _RowInfoCell(
              icon: Icons.calendar_today,
              title: 'Data de saída:',
              value: outDate ?? '',
            ),
          ),
      ],
    );
  }
}

class _ColumnInfoCell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ColumnInfoCell({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(icon, size: 16, color: Colors.black54),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _RowInfoCell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _RowInfoCell({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(icon, size: 16, color: Colors.black54),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
