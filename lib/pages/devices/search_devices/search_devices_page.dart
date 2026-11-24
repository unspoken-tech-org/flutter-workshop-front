import 'package:flutter_workshop_front/core/di/app_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/device/device_search_filter.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/controllers/search_devices_controller.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/widgets/search_devices_view.dart';
import 'package:provider/provider.dart';

class SearchDevicesPage extends StatelessWidget {
  static const route = '/search-devices';
  final DeviceSearchFilter? filter;
  const SearchDevicesPage({super.key, this.filter});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SearchDevicesController(
        context.read<AppDependencies>().allDevicesRepository,
        filter: filter,
      ),
      child: const SearchDevicesView(),
    );
  }
}
