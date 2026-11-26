import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/device/device_query.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/controllers/all_devices_controller.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/widgets/all_devices_view.dart';
import 'package:flutter_workshop_front/repositories/catalog/catalog_repository.dart';
import 'package:flutter_workshop_front/repositories/device/device_repository.dart';
import 'package:flutter_workshop_front/widgets/core/ui_message_listener.dart';
import 'package:provider/provider.dart';

class AllDevicesPage extends StatelessWidget {
  static const route = '/all-devices';
  final DeviceQuery? query;
  const AllDevicesPage({super.key, this.query});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AllDevicesController(
        context.read<DeviceRepository>(),
        context.read<CatalogRepository>(),
        query: query,
      ),
      child: const ProviderUiMessageListener<AllDevicesController>(
        child: AllDevicesView(),
      ),
    );
  }
}
