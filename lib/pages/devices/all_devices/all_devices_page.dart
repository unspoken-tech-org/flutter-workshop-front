import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/controllers/all_devices_controller.dart';
import 'package:flutter_workshop_front/repositories/all_devices/all_devices_remote_data_source.dart';
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
        AllDevicesRemoteDataSource(),
        filter: filter,
      ),
      child: const AllDevicesView(),
    );
  }
}
