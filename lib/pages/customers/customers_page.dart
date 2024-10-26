import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  @override
  Widget build(BuildContext context) {
    return const WsScaffold(child: Placeholder());
  }
}
