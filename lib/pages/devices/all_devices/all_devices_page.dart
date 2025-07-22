import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/controllers/all_devices_controller.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/widgets/all_devices_header.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/widgets/all_devices_header_filter_widget.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/widgets/device_card_shimmer.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/widgets/order_by_overlay_button_view.dart';
import 'package:flutter_workshop_front/repositories/all_devices/all_devices_remote_data_source.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';
import 'package:flutter_workshop_front/widgets/device/filtered_device_card.dart';
import 'package:provider/provider.dart';

class AllDevicesPage extends StatelessWidget {
  static const route = '/all-devices';
  const AllDevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WsScaffold(
      child: ChangeNotifierProvider(
        create: (context) => AllDevicesController(AllDevicesRemoteDataSource()),
        lazy: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: Column(
                spacing: 16,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      spacing: 16,
                      children: [
                        AllDevicesHeader(),
                        AllDevicesHeaderFilterWidget(),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OrderByButtonView(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Selector<AllDevicesController,
                        (bool, List<DeviceDataTable>)>(
                      selector: (context, controller) =>
                          (controller.isLoading, controller.devices),
                      builder: (context, values, _) {
                        final (isLoading, devices) = values;
                        if (isLoading) {
                          return ListView.builder(
                            itemCount: 10,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemBuilder: (context, index) {
                              return const DeviceCardShimmer();
                            },
                          );
                        }
                        return ListView.builder(
                          itemCount: devices.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            return FilteredDeviceCard(
                              device: devices[index],
                              onTap: () {
                                WsNavigator.pushDeviceDetails(
                                    context, devices[index].deviceId);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
