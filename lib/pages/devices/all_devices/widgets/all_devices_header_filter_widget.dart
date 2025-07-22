import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/controllers/all_devices_controller.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/widgets/all_devices_filter_list_view.dart';
import 'package:flutter_workshop_front/widgets/ws_search_bar_widget.dart';
import 'package:provider/provider.dart';

class AllDevicesHeaderFilterWidget extends StatelessWidget {
  const AllDevicesHeaderFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AllDevicesController>();

    return Column(
      children: [
        WsSearchBarWidget(
          labelText: 'Buscar por nome, CPF, ID ou telefone',
          onChanged: controller.filterTable,
          onClear: () => controller.clearSearch(),
        ),
        Selector<AllDevicesController, bool>(
          selector: (context, controller) => controller.isFiltering,
          builder: (context, isFiltering, _) {
            return AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              child: isFiltering
                  ? const AllDevicesFilterListView()
                  : const SizedBox.shrink(),
            );
          },
        ),
      ],
    );
  }
}
