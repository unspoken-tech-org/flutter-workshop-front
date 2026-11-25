import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/widgets/core/ws_drawer/ws_drawer.dart';
import 'package:flutter_workshop_front/widgets/core/ws_drawer/ws_drawer_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

Widget _drawerApp(WsDrawerController controller) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: WsDrawer.expandedWidth,
              child: WsDrawer(currentRoute: ''),
            ),
          ),
        ),
      ),
    ],
  );
  return ChangeNotifierProvider.value(
    value: controller,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('expanded header keeps the collapse button inside the drawer', (
    tester,
  ) async {
    final controller = WsDrawerController()..expand();
    await tester.pumpWidget(_drawerApp(controller));
    await tester.pumpAndSettle();

    final toggle = find.byTooltip('Alternar menu');
    expect(toggle, findsOneWidget);
    final rect = tester.getRect(toggle);
    expect(rect.right, lessThanOrEqualTo(WsDrawer.expandedWidth));

    final title = tester.getRect(find.text('Eletroluk WorkShop'));
    expect(title.right, lessThanOrEqualTo(rect.left));

    await tester.tap(toggle);
    await tester.pump();
    expect(controller.isExpanded, isFalse);
  });
}
