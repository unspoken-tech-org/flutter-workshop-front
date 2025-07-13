import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/widgets/customer_device/customer_device_info_header_widget.dart';
import 'package:flutter_workshop_front/widgets/customer_device/customer_device_observation_widget.dart';
import 'package:flutter_workshop_front/widgets/customer_device/customer_device_technical_info_widget.dart';
import 'package:flutter_workshop_front/widgets/customer_device/device_customer_cancel_button.dart';
import 'package:flutter_workshop_front/widgets/customer_device/device_customer_save_button.dart';
import 'package:flutter_workshop_front/widgets/customer_device/device_details_widget.dart';
import 'package:flutter_workshop_front/widgets/customer_device/device_values_widget.dart';
import 'package:flutter_workshop_front/widgets/customer_device/diagnostic_device_info_widget.dart';

class CustomerDeviceInfosWidget extends StatefulWidget {
  const CustomerDeviceInfosWidget({super.key});

  @override
  State<CustomerDeviceInfosWidget> createState() =>
      _CustomerDeviceInfosWidgetState();
}

class _CustomerDeviceInfosWidgetState extends State<CustomerDeviceInfosWidget> {
  final _formKey = GlobalKey<FormState>();
  bool isEditing = false;
  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceCustomerController.of(context);
    final deviceCustomer = controller.deviceCustomer.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          spacing: 28,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomerDeviceInfoHeaderWidget(),
            Row(
              spacing: 28,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Column(
                    spacing: 28,
                    children: [
                      DeviceDetailsWidget(deviceCustomer: deviceCustomer),
                      DiagnosticDeviceInfoWidget(
                        problem: deviceCustomer.problem,
                        budget: deviceCustomer.budget ?? '',
                        isEditing: isEditing,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Column(
                    spacing: 28,
                    children: [
                      DeviceValuesWidget(
                        laborValue: deviceCustomer.laborValue ?? 0,
                        serviceValue: deviceCustomer.serviceValue ?? 0,
                        laborValueCollected: deviceCustomer.laborValueCollected,
                        isEditing: isEditing,
                      ),
                      CustomerDeviceObservationWidget(
                        observation: deviceCustomer.observation,
                        isEditing: isEditing,
                      ),
                      CustomerDeviceTechnicalInfoWidget(
                        isEditing: isEditing,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(color: Colors.grey.shade200, height: 1),
            Row(
              spacing: 16,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isEditing)
                  DeviceCustomerCancelButton(
                    onCancel: () {
                      setState(() => isEditing = false);
                      _formKey.currentState?.reset();
                    },
                  ),
                DeviceCustomerSaveButton(
                  onSave: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _formKey.currentState?.save();

                      controller.updateDeviceCustomer();
                      setState(() => isEditing = false);
                    }
                  },
                  onEdit: () => setState(() => isEditing = true),
                  isEditing: isEditing,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
