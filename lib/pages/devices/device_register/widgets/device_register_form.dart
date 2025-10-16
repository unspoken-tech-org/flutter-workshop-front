import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/controller/device_register_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/widgets/customer_infos.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/widgets/device_details_register_form.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/widgets/device_register_header.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/widgets/problem_description_form.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/widgets/technician_and_urgency_form.dart';
import 'package:provider/provider.dart';

class DeviceRegisterForm extends StatefulWidget {
  const DeviceRegisterForm({super.key});

  @override
  State<DeviceRegisterForm> createState() => _DeviceRegisterFormState();
}

class _DeviceRegisterFormState extends State<DeviceRegisterForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _formKey.currentState?.dispose();
    super.dispose();
  }

  Future<void> _createDevice(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState?.save();

    int? deviceId =
        await context.read<DeviceRegisterController>().createDevice();
    if (deviceId != null && context.mounted) {
      WsNavigator.pushDeviceDetails(context, deviceId, replaced: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DeviceRegisterHeader(),
            const CustomerInfos(),
            Selector<DeviceRegisterController, bool>(
              selector: (context, controller) => controller.isCustomerSelected,
              builder: (context, isCustomerSelected, child) {
                if (!isCustomerSelected) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 16,
                  children: [
                    const ProblemDescriptionForm(),
                    const DeviceDetailsRegisterForm(),
                    const TechnicianAndUrgencyForm(),
                    DeviceRegisterActionButtons(
                      onCancel: () {
                        _formKey.currentState?.reset();
                        Navigator.pop(context);
                      },
                      onSave: () async {
                        await _createDevice(context);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceRegisterActionButtons extends StatelessWidget {
  final VoidCallback onCancel;
  final Future<void> Function() onSave;
  const DeviceRegisterActionButtons(
      {super.key, required this.onCancel, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () {
                onCancel();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                foregroundColor: Colors.black87,
                backgroundColor: Colors.white.withAlpha(230),
              ),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 16),
            Selector<DeviceRegisterController, bool>(
              selector: (context, controller) => controller.isCreatingDevice,
              builder: (context, isCreatingDevice, child) {
                return SizedBox(
                  width: 220,
                  child: ElevatedButton.icon(
                    onPressed:
                        isCreatingDevice ? null : () async => await onSave(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                    ),
                    icon: isCreatingDevice
                        ? null
                        : const Icon(Icons.save_outlined),
                    label: isCreatingDevice
                        ? const Center(
                            child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black87,
                            ),
                          ))
                        : const Text('Cadastrar Aparelho'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
