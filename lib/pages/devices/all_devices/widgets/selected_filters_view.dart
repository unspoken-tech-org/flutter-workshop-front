import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/controllers/all_devices_controller.dart';
import 'package:provider/provider.dart';

class SelectedFiltersView extends StatelessWidget {
  const SelectedFiltersView({
    super.key,
    required this.controller,
  });

  final AllDevicesController controller;

  @override
  Widget build(BuildContext context) {
    return Selector<AllDevicesController, DeviceFilter>(
      selector: (context, controller) => controller.filter,
      builder: (context, filter, _) {
        final filteredTypes = filter.deviceTypes;
        final filteredBrands = filter.deviceBrands;
        final filteredStatus = filter.status;

        if (filteredTypes.isEmpty &&
            filteredBrands.isEmpty &&
            filteredStatus.isEmpty) {
          return const SizedBox();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var item in filteredTypes)
                Chip(
                  label: Text('Tipo: ${item.typeName}'),
                  backgroundColor: Colors.grey.shade100,
                  onDeleted: () {
                    controller.addRemoveDeviceType(item);
                  },
                ),
              for (var item in filteredBrands)
                Chip(
                  label: Text('Marca: ${item.brand}'),
                  backgroundColor: Colors.grey.shade100,
                  onDeleted: () {
                    controller.addRemoveDeviceBrand(item);
                  },
                ),
              for (var item in filteredStatus)
                Chip(
                  label: Text('Status: ${item.displayName}'),
                  backgroundColor: Colors.grey.shade100,
                  onDeleted: () {
                    controller.addRemoveStatus(item);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
