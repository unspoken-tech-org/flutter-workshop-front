import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/widgets/device_card_shimmer.dart';
import 'package:flutter_workshop_front/pages/home/controllers/home_controller.dart';
import 'package:flutter_workshop_front/widgets/device/filtered_device_card.dart';
import 'package:provider/provider.dart';

class RecentDevicesView extends StatelessWidget {
  const RecentDevicesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Column(
        spacing: 24,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(
              top: 16,
            ),
            child: const Row(
              children: [
                Icon(Icons.history, size: 20),
                SizedBox(width: 8),
                Text(
                  'Aparelhos Recentes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 400,
            child: Selector<HomeController, (bool, List<DeviceDataTable>)>(
              selector: (context, controller) => (
                controller.isLoading,
                controller.deviceStatistics?.lastViewedDevices ?? []
              ),
              builder: (context, values, child) {
                final (isLoading, devices) = values;

                if (isLoading) {
                  return ListView.builder(
                    itemCount: 10,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) => const DeviceCardShimmer(),
                  );
                }
                if (devices.isEmpty) {
                  return const Center(
                    child: Text('Nenhum aparelho recente'),
                  );
                }
                return ListView.builder(
                  itemCount: devices.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
                    bottom: 16,
                  ),
                  itemBuilder: (context, index) => FilteredDeviceCard(
                    device: devices[index],
                    onTap: () {
                      WsNavigator.pushDeviceDetails(
                              context, devices[index].deviceId)
                          .then((value) {
                        if (context.mounted) {
                          context.read<HomeController>().getDeviceStatistics();
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
