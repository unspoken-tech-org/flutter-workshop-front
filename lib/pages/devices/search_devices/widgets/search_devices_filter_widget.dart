import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/controllers/search_devices_controller.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/widgets/search_devices_filter_button_view.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/widgets/search_devices_filter_list_view.dart';
import 'package:flutter_workshop_front/widgets/ws_search_bar_widget.dart';
import 'package:provider/provider.dart';

class SearchDevicesHeaderFilterWidget extends StatelessWidget {
  const SearchDevicesHeaderFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SearchDevicesController>();

    return Column(
      children: [
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: WsSearchBarWidget(
                labelText: 'Buscar por nome, tipo, marca ou modelo',
                onChanged: controller.filterTable,
                onClear: () => controller.clearSearch(),
              ),
            ),
            const SearchFilterButtonView(),
          ],
        ),
        Selector<SearchDevicesController, bool>(
          selector: (context, controller) => controller.isFiltering,
          builder: (context, isFiltering, _) {
            return AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              child: isFiltering
                  ? const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: SearchDevicesFilterListView(),
                    )
                  : const SizedBox.shrink(),
            );
          },
        ),
      ],
    );
  }
}
