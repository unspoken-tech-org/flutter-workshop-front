import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_phones.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/device_status_chip.dart';
import 'package:flutter_workshop_front/utils/phone_utils.dart';
import 'package:flutter_workshop_front/widgets/customer_device/revision_chip.dart';
import 'package:flutter_workshop_front/widgets/customer_device/urgency_chip.dart';
import 'package:provider/provider.dart';

class CustomerDeviceInfoHeaderWidget extends StatefulWidget {
  const CustomerDeviceInfoHeaderWidget({
    super.key,
  });

  @override
  State<CustomerDeviceInfoHeaderWidget> createState() =>
      _CustomerDeviceInfoHeaderWidgetState();
}

class _CustomerDeviceInfoHeaderWidgetState
    extends State<CustomerDeviceInfoHeaderWidget> {
  bool isHoveringCustomer = false;

  String getMainPhone(List<CustomerPhones> customerPhones) =>
      PhoneUtils.formatPhone(
          customerPhones.firstWhere((phone) => phone.isMain).number);

  Future<void> _executeUpdateOrShowDialog(
    BuildContext context, {
    required Future<void> Function() onConfirm,
    required StatusEnum actualStatus,
    required String message,
  }) async {
    if (![StatusEnum.delivered, StatusEnum.disposed].contains(actualStatus)) {
      await onConfirm();
      return Future.value();
    }
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aviso'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            child: const Text('Prosseguir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<DeviceCustomerPageController, DeviceCustomer>(
      selector: (context, controller) => controller.deviceCustomer,
      builder: (context, deviceCustomer, child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ID do aparelho # ${deviceCustomer.deviceId}',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                spacing: 8,
                children: [
                  UrgencyChip(
                    hasUrgency: deviceCustomer.hasUrgency,
                    onTap: () async {
                      await _executeUpdateOrShowDialog(
                        context,
                        actualStatus: deviceCustomer.deviceStatus,
                        message:
                            'Alterar o status de urgência fara com que o status do aparelho seja alterado para "Novo". Deseja Prosseguir?',
                        onConfirm: () async {
                          await context
                              .read<DeviceCustomerPageController>()
                              .updateDeviceHasUrgency(
                                !deviceCustomer.hasUrgency,
                              );
                          setState(() {});
                        },
                      );
                    },
                  ),
                  RevisionChip(
                    revision: deviceCustomer.revision,
                    onTap: () async {
                      await _executeUpdateOrShowDialog(
                        context,
                        actualStatus: deviceCustomer.deviceStatus,
                        message:
                            'Alterar o status de revisão fara com que o status do aparelho seja alterado para "Novo". Deseja Prosseguir?',
                        onConfirm: () async {
                          await context
                              .read<DeviceCustomerPageController>()
                              .updateDeviceRevision(!deviceCustomer.revision);
                          setState(() {});
                        },
                      );
                    },
                  ),
                  DeviceStatusChip(
                    key: GlobalKey(),
                    status: deviceCustomer.deviceStatus,
                    onSelect: (status) async {
                      await context
                          .read<DeviceCustomerPageController>()
                          .updateDeviceStatus(status);
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
                        'Cliente: ${deviceCustomer.customerName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isHoveringCustomer
                                  ? Colors.lightBlueAccent
                                  : Colors.black,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  spacing: 8,
                  children: [
                    const Icon(Icons.phone_outlined),
                    Expanded(
                      child: Text(
                        overflow: TextOverflow.ellipsis,
                        'Telefone principal: ${getMainPhone(deviceCustomer.customerPhones)}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
