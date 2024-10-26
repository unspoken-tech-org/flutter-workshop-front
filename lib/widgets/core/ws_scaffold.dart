import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';

class WsScaffold extends StatefulWidget {
  final Widget child;
  const WsScaffold({
    super.key,
    required this.child,
  });

  @override
  State<WsScaffold> createState() => _WsScaffoldState();
}

class _WsScaffoldState extends State<WsScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PreferredSize(
          preferredSize: Size.fromHeight(200), child: HomeButtonsHeader()),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: widget.child,
      ),
    );
  }
}

class HomeButtonsHeader extends StatelessWidget {
  const HomeButtonsHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            spreadRadius: 5,
            blurRadius: 10,
            blurStyle: BlurStyle.outer,
            offset: Offset(15, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              FilledButton.icon(
                onPressed: () {
                  WsNavigator.pushHome(context);
                },
                style: FilledButton.styleFrom(fixedSize: const Size(132, 34)),
                icon: const Icon(Icons.home),
                label: const Text('Home'),
              ),
              const SizedBox(width: 18),
              FilledButton.icon(
                onPressed: () {
                  WsNavigator.pushCustomers(context);
                },
                style: FilledButton.styleFrom(fixedSize: const Size(132, 34)),
                icon: const Icon(Icons.person),
                label: const Text('Clientes'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
