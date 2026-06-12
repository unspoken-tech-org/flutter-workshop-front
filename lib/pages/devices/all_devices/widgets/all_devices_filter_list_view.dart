import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/controllers/all_devices_controller.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/widgets/selected_filters_view.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_date_form_field.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_dropdown_button_form_field.dart';
import 'package:flutter_workshop_front/widgets/form_fields/searchable_dropdown_form_field.dart';
import 'package:flutter_workshop_front/widgets/form_fields/switch_form_field.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AllDevicesFilterListView extends StatelessWidget {
  const AllDevicesFilterListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AllDevicesController>();

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        spacing: 16,
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
          Row(
            children: [
              Selector<AllDevicesController, DeviceFilter>(
                selector: (context, controller) => controller.filter,
                builder: (context, filter, _) {
                  final String rangeDate =
                      [filter.initialEntryDate, filter.finalEntryDate].nonNulls
                          .map((e) => DateFormat('dd/MM/yyyy').format(e))
                          .join(' - ');
                  return Flexible(
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
                  );
                },
              ),
              const Flexible(child: SizedBox()),
              const Flexible(child: SizedBox()),
            ],
          ),
          Row(
            spacing: 16,
            children: [
              Selector<AllDevicesController, List<DeviceType>>(
                selector: (context, controller) => controller.deviceTypes,
                builder: (context, deviceTypes, _) {
                  return Flexible(
                    child: SearchableDropdownFormField<DeviceType>(
                      headerLabelText: 'Tipo de aparelho',
                      hintText: 'Busque pelo tipo',
                      searchFn: (query) async {
                        if (query.isEmpty) return deviceTypes;
                        return deviceTypes
                            .where((e) => e.typeName
                                .toLowerCase()
                                .contains(query.toLowerCase()))
                            .toList();
                      },
                      getName: (item) => item.typeName,
                      getId: (item) => item.idType,
                      onAccept: (deviceType) {
                        controller.addRemoveDeviceType(deviceType);
                      },
                    ),
                  );
                },
              ),
              Selector<AllDevicesController, List<DeviceBrand>>(
                selector: (context, controller) => controller.deviceBrands,
                builder: (context, deviceBrands, _) {
                  return Flexible(
                    child: SearchableDropdownFormField<DeviceBrand>(
                      headerLabelText: 'Marca do aparelho',
                      hintText: 'Busque pela marca',
                      searchFn: (query) async {
                        if (query.isEmpty) return deviceBrands;
                        return deviceBrands
                            .where((e) => e.brand
                                .toLowerCase()
                                .contains(query.toLowerCase()))
                            .toList();
                      },
                      getName: (item) => item.brand,
                      getId: (item) => item.idBrand,
                      onAccept: (deviceBrand) {
                        controller.addRemoveDeviceBrand(deviceBrand);
                      },
                    ),
                  );
                },
              ),
              Selector<AllDevicesController, DeviceFilter>(
                selector: (context, controller) => controller.filter,
                builder: (context, filter, _) {
                  final statusNames = StatusEnum.values
                      .map((e) => e.displayName)
                      .toList();

                  return Flexible(
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
                  );
                },
              ),
            ],
          ),
          SelectedFiltersView(controller: controller),
          Selector<AllDevicesController, DeviceFilter>(
            selector: (context, controller) => controller.filter,
            builder: (context, filter, _) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    flex: 2,
                    child: Row(
                      spacing: 16,
                      children: [
                        Row(
                          spacing: 4,
                          children: [
                            SwitchFormField(
                              initialValue: controller.filter.hasUrgency,
                              onChanged: (value) {
                                controller.toggleUrgency();
                              },
                            ),
                            const Text(
                              'Apenas urgentes',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          spacing: 4,
                          children: [
                            SwitchFormField(
                              initialValue: controller.filter.hasRevision,
                              onChanged: (value) {
                                controller.toggleRevision();
                              },
                            ),
                            const Text(
                              'Apenas revisões',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
