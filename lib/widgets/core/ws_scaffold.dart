import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/widgets/core/ws_drawer/ws_drawer.dart';
import 'package:go_router/go_router.dart';

class WsScaffold extends StatefulWidget {
  final Widget child;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const WsScaffold({
    super.key,
    required this.child,
    this.backgroundColor,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  State<WsScaffold> createState() => _WsScaffoldState();
}

class _WsScaffoldState extends State<WsScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? Colors.white,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 55),
            child: widget.child,
          ),
          WsDrawer(
            currentRoute: GoRouterState.of(context).name ?? '',
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
    );
  }
}
