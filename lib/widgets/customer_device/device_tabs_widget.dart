import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/widgets/customer_device/customer_contacts_tab.dart';
import 'package:flutter_workshop_front/widgets/customer_device/customer_devices_list.dart';
import 'package:flutter_workshop_front/widgets/shared/empty_list_widget.dart';

class DeviceTabsWidget extends StatelessWidget {
  const DeviceTabsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final controller = InheritedDeviceCustomerController.of(context);
    return SizedBox(
      width: size.width * 0.7,
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: size.width * 0.27,
              child: TabBar(
                tabs: const [
                  Tab(text: 'Contatos'),
                  Tab(text: 'Outros Aparelhos'),
                ],
                labelColor: const Color(0xFF6366F1),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF6366F1),
                indicatorWeight: 0.1,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                dividerHeight: 0,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                indicatorPadding: EdgeInsets.zero,
                labelStyle: WsTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                unselectedLabelStyle: WsTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: size.width * 0.7,
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
                child: TabBarView(
                  children: [
                    const CustomerContactsTab(),
                    Visibility(
                      visible: controller
                          .newDeviceCustomer.value.otherDevices.isNotEmpty,
                      replacement: const EmptyListWidget(
                        message:
                            'Não foram encontrado outros aparelhos para este cliente',
                      ),
                      child: CustomerDevicesList(
                        customerDevices:
                            controller.newDeviceCustomer.value.otherDevices,
                        onTap: (id) {
                          controller.init(id);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
