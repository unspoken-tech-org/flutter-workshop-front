import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/device/device_search_filter.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/controllers/search_devices_controller.dart';
import 'package:provider/provider.dart';

class SearchSelectedFiltersView extends StatelessWidget {
  const SearchSelectedFiltersView({
    super.key,
    required this.controller,
  });

  final SearchDevicesController controller;

  @override
  Widget build(BuildContext context) {
    return Selector<SearchDevicesController, DeviceSearchFilter>(
      selector: (context, controller) => controller.filter,
      builder: (context, filter, _) {
        final filteredStatus = filter.status;

        if (filteredStatus.isEmpty) {
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
