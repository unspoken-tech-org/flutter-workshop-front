import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/controllers/search_devices_controller.dart';
import 'package:provider/provider.dart';

class SearchOrderByItemView extends StatelessWidget {
  final OrderBy orderBy;
  final OrderDirection? orderDirection;
  const SearchOrderByItemView(
      {super.key, required this.orderBy, this.orderDirection});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        context.read<SearchDevicesController>().toggleOrderBy(orderBy);
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      label: Text(
        orderBy.displayName,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      iconAlignment: IconAlignment.end,
      icon: orderDirection == null
          ? null
          : Icon(
              orderDirection == OrderDirection.asc
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: Colors.black,
            ),
    );
  }
}
