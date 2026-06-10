import 'package:flutter/material.dart';

class SearchDevicesHeader extends StatelessWidget {
  const SearchDevicesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Buscar Aparelhos',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
