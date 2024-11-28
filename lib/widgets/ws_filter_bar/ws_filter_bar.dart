import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_colors.dart';
import 'package:flutter_workshop_front/pages/home/controllers/home_controller.dart';
import 'package:flutter_workshop_front/utils/filter_utils.dart';
import 'package:flutter_workshop_front/widgets/rounded_filter_bar.dart';

class WsFilterBar extends StatefulWidget {
  final HomeController controller;

  const WsFilterBar({
    super.key,
    required this.controller,
  });

  @override
  State<WsFilterBar> createState() => _WsFilterBarState();
}

class _WsFilterBarState extends State<WsFilterBar> {
  final _textController = TextEditingController();

  void filterTable() {
    var filter = widget.controller.filter;
    filter.clearTypedFilters();

    var search = FilterUtils(_textController.text);
    if (search.isName) {
      filter.customerName = search.term;
    } else if (search.isCpf) {
      filter.customerCpf = search.term.replaceAll('.', '').replaceAll('-', '');
    } else if (search.isPhoneOrCellPhone) {
      filter.customerPhone = search.term;
    } else if (search.isDeviceId) {
      filter.deviceId = int.parse(search.term);
    }
    widget.controller.getTableData(filter);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Row(
        children: [
          Expanded(
            child: RoundedFilterBar(
              controller: _textController,
              onEnter: () => filterTable(),
              onClear: () => filterTable(),
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            label: const Text('Filtrar'),
            icon: const Icon(Icons.filter_alt_outlined),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: WsColors.primary, width: 2),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
