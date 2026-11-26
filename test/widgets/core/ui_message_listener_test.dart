import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/ui/ui_message.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';
import 'package:flutter_workshop_front/widgets/core/ui_message_listener.dart';

void main() {
  group('UiMessageListener', () {
    testWidgets('exibe sucesso e erro publicados pela fonte', (tester) async {
      final bus = UiMessageBus();
      addTearDown(bus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: SnackBarUtil().scaffoldKey,
          builder: (context, child) =>
              UiMessageListener(source: bus, child: child!),
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      );

      bus.publish(const UiSuccess('Salvo'));
      await tester.pump();
      expect(find.text('Salvo'), findsOneWidget);

      bus.publish(const UiError('Falhou'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Falhou'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('troca a assinatura quando a fonte muda', (tester) async {
      final first = UiMessageBus();
      final second = UiMessageBus();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      Widget host(UiMessageBus bus) => MaterialApp(
        scaffoldMessengerKey: SnackBarUtil().scaffoldKey,
        home: Scaffold(
          body: UiMessageListener(source: bus, child: const SizedBox.shrink()),
        ),
      );

      await tester.pumpWidget(host(first));
      await tester.pumpWidget(host(second));
      first.publish(const UiError('da fonte antiga'));
      second.publish(const UiError('da fonte nova'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('da fonte antiga'), findsNothing);
      expect(find.text('da fonte nova'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
    });
  });
}
