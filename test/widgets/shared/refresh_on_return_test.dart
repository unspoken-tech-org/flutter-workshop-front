import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/widgets/shared/refresh_on_return.dart';

void main() {
  testWidgets('fires when a pushed route is popped', (tester) async {
    var calls = 0;
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: RefreshOnReturn(
          onReturn: () => calls++,
          child: const Text('lista'),
        ),
      ),
    );
    expect(calls, 0);

    unawaited(
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Text('detalhe')),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 0);

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('fires when the pushed route was replaced and then popped', (
    tester,
  ) async {
    var calls = 0;
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: RefreshOnReturn(
          onReturn: () => calls++,
          child: const Text('lista'),
        ),
      ),
    );

    unawaited(
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Text('cadastro')),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(
      navigatorKey.currentState!.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const Text('detalhe')),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 0);

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(calls, 1);
  });
}
