import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';
import 'package:flutter_workshop_front/widgets/customer_device/customer_contacts_list.dart';
import 'package:flutter_workshop_front/widgets/customer_device/other_devices_list.dart';

class DeviceTabsWidget extends StatelessWidget {
  const DeviceTabsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
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
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.transparent,
                dividerColor: Colors.transparent,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                dividerHeight: 0,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                indicatorPadding: EdgeInsets.zero,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: WsTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                unselectedLabelStyle: WsTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: size.height * 0.37,
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
              child: const TabBarView(
                children: [
                  CustomerContactsList(),
                  OtherDevicesList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
