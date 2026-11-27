import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/widgets/core/ws_drawer/ws_drawer.dart';
import 'package:flutter_workshop_front/widgets/core/ws_drawer/ws_drawer_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class WsScaffold extends StatelessWidget {
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

  // The error page (unknown deep link) is built without a GoRouterState.
  static String _currentRouteName(BuildContext context) {
    try {
      return GoRouterState.of(context).name ?? '';
    } on GoError {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.white,
      body: Selector<WsDrawerController, double>(
        selector: (_, c) =>
            c.isExpanded ? WsDrawer.expandedWidth : WsDrawer.collapsedWidth,
        builder: (context, drawerWidth, _) => Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: drawerWidth,
              child: WsDrawer(currentRoute: _currentRouteName(context)),
            ),
            Expanded(child: child),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
