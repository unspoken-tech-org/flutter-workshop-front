import 'package:flutter_workshop_front/core/format/br_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/date_time_extension.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_date_form_field.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_text_field.dart';
import 'package:provider/provider.dart';

class DeviceDetailsWidget extends StatelessWidget {
  final bool isEditing;

  const DeviceDetailsWidget({super.key, this.isEditing = false});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DeviceCustomerPageController>();

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Selector<DeviceCustomerPageController, DeviceCustomer?>(
        selector: (context, controller) => controller.deviceCustomer,
        builder: (context, deviceCustomer, child) {
          if (deviceCustomer == null) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.build_outlined, color: Color(0xFF4B5563)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detalhes do Aparelho',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CustomTextField(
                headerLabel: 'Aparelho',
                readOnly: true,
                maxLines: 1,
                value:
                    '${deviceCustomer.typeName} ${deviceCustomer.brandName} | ${deviceCustomer.modelName}'
                        .capitalizeAllWords,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                headerLabel: 'Cores',
                readOnly: true,
                value: deviceCustomer.deviceColors.join(', '),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomDateFormField(
                      enabled: isEditing,
                      errorMaxLines: 2,
                      headerLabel: 'Data de entrada',
                      semanticsIdentifier: 'deviceDetail.entryDate',
                      value: deviceCustomer.entryDate.formatDate(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Data de entrada é obrigatória';
                        }
                        return null;
                      },
                      onSelected: (date, _) {
                        final current = controller.deviceCustomer;
                        if (current == null) return;
                        final updated = current.copyWith(entryDate: date);
                        controller.updateNewDeviceCustomer(updated);
                      },
                      onSave: (value) {
                        final current = controller.deviceCustomer;
                        if (current == null) return;
                        final updated = current.copyWith(
                          entryDate: BrFormat.parseDate(value),
                        );
                        controller.updateNewDeviceCustomer(updated);
                      },
                    ),
                  ),
                  if (deviceCustomer.departureDate != null ||
                      (isEditing &&
                          [
                            StatusEnum.delivered,
                            StatusEnum.disposed,
                          ].contains(deviceCustomer.deviceStatus))) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomDateFormField(
                        enabled: isEditing,
                        headerLabel: 'Data de saída',
                        semanticsIdentifier: 'deviceDetail.departureDate',
                        value: deviceCustomer.departureDate?.formatDate() ?? '',
                        errorMaxLines: 2,
                        validator: (value) {
                          final current = controller.deviceCustomer;
                          if (current == null) return null;
                          if ([
                            StatusEnum.delivered,
                            StatusEnum.disposed,
                          ].contains(current.deviceStatus)) {
                            if (value == null || value.isEmpty) {
                              return 'Saída obrigatória para entregue/descartado';
                            }
                          }
                          if (value != null && value.isNotEmpty) {
                            final entry = current.entryDate;
                            final departure = BrFormat.parseDate(value);
                            if (!departure.isAfter(entry)) {
                              return 'Data de saída deve ser posterior à entrada';
                            }
                          }
                          return null;
                        },
                        onSelected: (date, _) {
                          final current = controller.deviceCustomer;
                          if (current == null) return;
                          final updated = current.copyWith(departureDate: date);
                          controller.updateNewDeviceCustomer(updated);
                        },
                        onSave: (value) {
                          final current = controller.deviceCustomer;
                          if (current == null) return;
                          final updated = current.copyWith(
                            departureDate: value.isEmpty
                                ? null
                                : BrFormat.parseDate(value),
                          );
                          controller.updateNewDeviceCustomer(updated);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
