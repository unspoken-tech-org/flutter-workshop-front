import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/inherited_device_customer_controller.dart';

class DeviceCustomerSaveButton extends StatelessWidget {
  const DeviceCustomerSaveButton({
    super.key,
  });

  void _saveDeviceCustomer(DeviceCustomerPageController controller) {
    controller.saveDeviceCustomer();
  }

  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceCustomerController.of(context);

    return ValueListenableBuilder(
      valueListenable: controller.newDeviceCustomer,
      builder: (context, value, child) {
        var currentDeviceCustomer = controller.currentDeviceCustomer.value;
        var newDeviceCustomer = value;

        bool isChanged = currentDeviceCustomer != newDeviceCustomer;

        return TextButton.icon(
          onPressed: isChanged ? () => _saveDeviceCustomer(controller) : null,
          icon: const Icon(Icons.save),
          style: TextButton.styleFrom(
            backgroundColor: isChanged ? Colors.deepPurple : Colors.grey,
            iconColor: Colors.white,
          ),
          label: Text('Salvar',
              style: WsTextStyles.body1.copyWith(color: Colors.white)),
        );
      },
    );
  }
}
