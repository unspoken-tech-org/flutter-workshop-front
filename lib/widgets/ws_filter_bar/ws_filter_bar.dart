import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/widgets/rounded_filter_bar.dart';

class WsFilterBar extends StatefulWidget {
  const WsFilterBar({super.key});

  @override
  State<WsFilterBar> createState() => _WsFilterBarState();
}

class _WsFilterBarState extends State<WsFilterBar> {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Row(
        children: [
          Expanded(child: RoundedFilterBar()),
          const SizedBox(width: 16),
          OutlinedButton.icon(
              onPressed: () {},
              label: const Text('Filtrar'),
              icon: const Icon(Icons.filter_alt_outlined)),
        ],
      ),
    );
  }
}
