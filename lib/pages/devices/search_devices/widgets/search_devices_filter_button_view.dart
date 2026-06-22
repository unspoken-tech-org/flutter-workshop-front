import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/device/device_search_filter.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/controllers/search_devices_controller.dart';
import 'package:provider/provider.dart';

class SearchFilterButtonView extends StatelessWidget {
  const SearchFilterButtonView({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<SearchDevicesController, (bool, DeviceSearchFilter)>(
      selector: (context, controller) =>
          (controller.isFiltering, controller.filter),
      builder: (context, values, _) {
        final (isFiltering, filter) = values;
        final filtersApplied = filter.filtersApplied;

        return Stack(
          children: [
            IconButton(
              onPressed: () {
                context.read<SearchDevicesController>().toggleFiltering();
              },
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(12),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              icon: Icon(
                isFiltering
                    ? Icons.filter_alt_off_outlined
                    : Icons.filter_alt_outlined,
                size: 24,
                color: Colors.black,
              ),
            ),
            if (filtersApplied > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: filtersApplied > 10 ? 6 : 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    filtersApplied.toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
