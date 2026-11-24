import 'package:flutter_workshop_front/core/di/app_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/controllers/all_devices_controller.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/widgets/all_devices_view.dart';
import 'package:provider/provider.dart';

class AllDevicesPage extends StatelessWidget {
  static const route = '/all-devices';
  final DeviceFilter? filter;
  const AllDevicesPage({super.key, this.filter});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AllDevicesController(
        context.read<AppDependencies>().allDevicesRepository,
        filter: filter,
      ),
      child: const AllDevicesView(),
    );
  }
}
