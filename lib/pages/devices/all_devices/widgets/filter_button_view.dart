import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/controllers/all_devices_controller.dart';
import 'package:provider/provider.dart';

class FilterButtonView extends StatelessWidget {
  const FilterButtonView({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AllDevicesController, (bool, DeviceFilter)>(
      selector: (context, controller) =>
          (controller.isFiltering, controller.filter),
      builder: (context, values, _) {
        final (isFiltering, filter) = values;
        final filtersApplied = filter.filtersApplied;

        return Stack(
          children: [
            TextButton.icon(
              onPressed: () {
                context.read<AllDevicesController>().toggleFiltering();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.fromLTRB(16, 16, 30, 16),
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
                size: 20,
                color: Colors.black,
              ),
              label: Text(
                isFiltering ? 'Ocultar Filtros' : 'Mostrar Filtros',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
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
