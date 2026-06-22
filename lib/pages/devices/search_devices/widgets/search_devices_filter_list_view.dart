import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/device/device_search_filter.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/controllers/search_devices_controller.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/widgets/search_devices_selected_filters_view.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_date_form_field.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_dropdown_button_form_field.dart';
import 'package:flutter_workshop_front/widgets/form_fields/switch_form_field.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SearchDevicesFilterListView extends StatelessWidget {
  const SearchDevicesFilterListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SearchDevicesController>();

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        spacing: 20,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  controller.clearFilters();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.transparent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                label: const Text(
                  'Limpar filtros',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                icon: const Icon(Icons.close, color: Colors.black),
              ),
            ],
          ),
          Selector<SearchDevicesController, DeviceSearchFilter>(
            selector: (context, controller) => controller.filter,
            builder: (context, filter, _) {
              final String rangeDate =
                  [filter.initialEntryDate, filter.finalEntryDate].nonNulls
                      .map((e) => DateFormat('dd/MM/yyyy').format(e))
                      .join(' - ');

              final statusNames = StatusEnum.values
                  .map((e) => e.displayName)
                  .toList();

              return Row(
                spacing: 18,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: CustomDateFormField(
                      headerLabel: 'Data de entrada',
                      hintText: 'Busque pela data de entrada',
                      value: rangeDate,
                      datePickerType: DatePickerType.range,
                      onSelected: (initialDate, endDate) {
                        controller.addRemoveEnterRangeDate(
                          initialDate,
                          endDate,
                        );
                      },
                      onClear: () {
                        controller.addRemoveEnterRangeDate(null, null);
                      },
                    ),
                  ),
                  Flexible(
                    child: CustomDropdownButtonFormField(
                      key: GlobalKey(),
                      headerLabel: 'Status do aparelho',
                      hintText: 'Busque pelo status',
                      items: statusNames,
                      onChanged: (value) {
                        if (value == null) return;
                        final status = StatusEnum.values.firstWhere(
                          (e) =>
                              e.displayName.toLowerCase() ==
                              value.toLowerCase(),
                        );
                        controller.addRemoveStatus(status);
                      },
                    ),
                  ),
                  Row(
                    spacing: 16,
                    children: [
                      Column(
                        spacing: 8,
                        children: [
                          const Text(
                            'Urgentes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SwitchFormField(
                            initialValue: filter.hasUrgency,
                            onChanged: (value) {
                              controller.toggleUrgency();
                            },
                          ),
                        ],
                      ),
                      Column(
                        spacing: 8,
                        children: [
                          const Text(
                            'Revisões',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SwitchFormField(
                            initialValue: filter.hasRevision,
                            onChanged: (value) {
                              controller.toggleRevision();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          SearchSelectedFiltersView(controller: controller),
        ],
      ),
    );
  }
}
