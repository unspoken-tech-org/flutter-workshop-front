import 'package:flutter/foundation.dart';
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
            padding: EdgeInsets.only(left: isDesktop ? 100 : 55),
            child: widget.child,
          ),
          if (isDesktop && GoRouter.of(context).canPop())
            Positioned(
              top: 20,
              left: 65,
              child: BackButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.white),
                  foregroundColor: WidgetStateProperty.all(Colors.black),
                ),
                onPressed: () => GoRouter.of(context).pop(),
              ),
            ),
          WsDrawer(currentRoute: GoRouterState.of(context).name ?? ''),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
    );
  }
}

final isDesktop = [
  TargetPlatform.windows,
  TargetPlatform.macOS,
].contains(defaultTargetPlatform);
