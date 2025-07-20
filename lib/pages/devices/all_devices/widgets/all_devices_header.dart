import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/widgets/filter_button_view.dart';

class AllDevicesHeader extends StatelessWidget {
  const AllDevicesHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Todos os Aparelhos',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w600,
          ),
        ),
        FilterButtonView(),
      ],
    );
  }
}
