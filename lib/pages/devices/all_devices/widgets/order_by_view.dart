import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/controllers/all_devices_controller.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/widgets/order_by_item_view.dart';
import 'package:provider/provider.dart';

class OrderByView extends StatelessWidget {
  const OrderByView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Ordenação',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Flexible(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<AllDevicesController>().clearOrderBy();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.transparent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  label: const Text(
                    'Limpar ordenação',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Selector<AllDevicesController, Map<OrderBy, OrderDirection?>>(
            selector: (context, controller) => controller.filter.orderBy,
            builder: (context, values, _) {
              final orderBy = values;

              return SizedBox(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...orderBy.entries.map(
                      (e) => OrderByItemView(
                        orderBy: e.key,
                        orderDirection: e.value,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
