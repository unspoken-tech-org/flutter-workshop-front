import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/widgets/core/ws_drawer/ws_drawer_controller.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('deep link to a location with no route renders the error page '
      'inside WsScaffold without throwing', (tester) async {
    final router = GoRouter(
      initialLocation: '/device-details/10',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/device/:id', builder: (_, _) => const SizedBox()),
      ],
      errorBuilder: (_, _) => const WsScaffold(child: Text('nao encontrada')),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => WsDrawerController(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('nao encontrada'), findsOneWidget);
  });
}
