import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_phones.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/device_status_chip.dart';
import 'package:flutter_workshop_front/core/format/br_format.dart';
import 'package:flutter_workshop_front/widgets/customer_device/revision_chip.dart';
import 'package:flutter_workshop_front/widgets/customer_device/urgency_chip.dart';
import 'package:provider/provider.dart';

class CustomerDeviceInfoHeaderWidget extends StatefulWidget {
  const CustomerDeviceInfoHeaderWidget({super.key});

  @override
  State<CustomerDeviceInfoHeaderWidget> createState() =>
      _CustomerDeviceInfoHeaderWidgetState();
}

class _CustomerDeviceInfoHeaderWidgetState
    extends State<CustomerDeviceInfoHeaderWidget> {
  bool isHoveringCustomer = false;

  String getMainPhone(List<CustomerPhones> customerPhones) {
    final mainPhone =
        customerPhones.firstWhereOrNull((phone) => phone.isMain) ??
        customerPhones.firstOrNull;
    if (mainPhone == null || mainPhone.number.isEmpty) {
      return 'Não informado';
    }
    return BrFormat.phone(mainPhone.number);
  }

  Future<void> _confirmOpenRevision(
    BuildContext context,
    DeviceCustomer origin,
  ) async {
    final controller = context.read<DeviceCustomerPageController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abrir revisão'),
        content: SizedBox(
          width: 360,
          child: Text(
            'Será aberta uma nova OS de revisão para '
            '${origin.customerName.capitalizeAllWords}, com o mesmo aparelho '
            '(${origin.typeName} ${origin.brandName} ${origin.modelName}), '
            'cores e defeito desta OS. A OS atual continua encerrada, com '
            'pagamentos e data de saída. Deseja prosseguir?',
          ),
        ),
        actions: [
          Semantics(
            identifier: 'deviceDetail.openRevision.cancel',
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
          ),
          Semantics(
            identifier: 'deviceDetail.openRevision.confirm',
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Abrir revisão'),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final newId = await controller.openRevisionOrder();
    if (newId == null || !context.mounted) return;
    await WsNavigator.pushDeviceDetails(context, newId, replaced: true);
  }

  @override
  Widget build(BuildContext context) {
    return Selector<DeviceCustomerPageController, (DeviceCustomer?, bool)>(
      selector: (context, controller) => (
        controller.deviceCustomer,
        controller.isUpdating || controller.isSaving,
      ),
      builder: (context, values, child) {
        final (deviceCustomer, isUpdating) = values;
        if (deviceCustomer == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID do aparelho # ${deviceCustomer.deviceId}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Semantics(
                      identifier: 'deviceDetail.urgency',
                      child: UrgencyChip(
                        hasUrgency: deviceCustomer.hasUrgency,
                        disabledTooltip: deviceCustomer.isClosed
                            ? 'OS encerrada: urgência não pode ser alterada'
                            : null,
                        onTap: isUpdating || deviceCustomer.isClosed
                            ? null
                            : () => unawaited(
                                context
                                    .read<DeviceCustomerPageController>()
                                    .updateDeviceHasUrgency(
                                      !deviceCustomer.hasUrgency,
                                    ),
                              ),
                      ),
                    ),
                    if (deviceCustomer.canOpenRevision)
                      Semantics(
                        identifier: 'deviceDetail.openRevision',
                        child: OutlinedButton.icon(
                          onPressed: isUpdating
                              ? null
                              : () => unawaited(
                                  _confirmOpenRevision(context, deviceCustomer),
                                ),
                          icon: const Icon(Icons.history, size: 16),
                          label: const Text('Abrir revisão'),
                        ),
                      )
                    else if (!deviceCustomer.isClosed)
                      Semantics(
                        identifier: 'deviceDetail.revision',
                        child: RevisionChip(
                          revision: deviceCustomer.revision,
                          onTap: isUpdating
                              ? null
                              : () => unawaited(
                                  context
                                      .read<DeviceCustomerPageController>()
                                      .updateDeviceRevision(
                                        !deviceCustomer.revision,
                                      ),
                                ),
                        ),
                      ),
                    DeviceStatusChip(
                      status: deviceCustomer.deviceStatus,
                      onSelect: isUpdating
                          ? null
                          : (status) async {
                              await context
                                  .read<DeviceCustomerPageController>()
                                  .updateDeviceStatus(status);
                              if (!mounted) return;
                              setState(() {});
                            },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              spacing: 32,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onHover: (event) {
                    setState(() {
                      isHoveringCustomer = true;
                    });
                  },
                  onExit: (event) {
                    setState(() {
                      isHoveringCustomer = false;
                    });
                  },
                  child: Semantics(
                    identifier: 'deviceDetail.customerLink',
                    child: GestureDetector(
                      onTap: () {
                        WsNavigator.pushCustomerDetail(
                          context,
                          deviceCustomer.customerId,
                        );
                      },
                      child: Row(
                        spacing: 8,
                        children: [
                          Icon(
                            Icons.person_outline,
                            color: isHoveringCustomer
                                ? Colors.lightBlueAccent
                                : Colors.black,
                          ),
                          Text(
                            'Cliente: ${deviceCustomer.customerName.capitalizeAllWords}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: isHoveringCustomer
                                      ? Colors.lightBlueAccent
                                      : Colors.black,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    spacing: 8,
                    children: [
                      const Icon(Icons.phone_outlined),
                      Expanded(
                        child: SelectableText(
                          'Telefone principal: ${getMainPhone(deviceCustomer.customerPhones)}',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
