import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/device_register_page.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/device_register_route_args.dart';
import 'package:go_router/go_router.dart';

class _Captured {
  Uri? uri;
  Object? extra;
  DeviceRegisterRouteArgs? args;
}

GoRouter _router(_Captured captured, void Function(BuildContext) onPush) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: TextButton(
            onPressed: () => onPush(context),
            child: const Text('go'),
          ),
        ),
      ),
      GoRoute(
        // Mesmo path/name da rota real em app_route.dart.
        path: '/device/register',
        name: DeviceRegisterPage.route,
        builder: (context, state) {
          captured
            ..uri = state.uri
            ..extra = state.extra
            ..args = DeviceRegisterRouteArgs.fromRoute(state.uri, state.extra);
          return const Scaffold(body: Text('device-register'));
        },
      ),
    ],
  );
}

Future<_Captured> _push(
  WidgetTester tester,
  void Function(BuildContext) onPush,
) async {
  final captured = _Captured();
  await tester.pumpWidget(
    MaterialApp.router(routerConfig: _router(captured, onPush)),
  );
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
  expect(find.text('device-register'), findsOneWidget);
  return captured;
}

void main() {
  group('WsNavigator.pushDeviceRegister', () {
    testWidgets('envia customerId na query e customerName apenas via extra', (
      tester,
    ) async {
      final captured = await _push(
        tester,
        (context) => WsNavigator.pushDeviceRegister(
          context,
          customerId: 10,
          customerName: 'Maria',
        ),
      );

      expect(captured.uri.toString(), '/device/register?customerId=10');
      expect(captured.uri.toString(), isNot(contains('customerName')));
      expect(captured.uri.toString(), isNot(contains('Maria')));
      expect(captured.extra, isA<DeviceRegisterExtra>());
      expect(captured.args?.customerId, 10);
      expect(captured.args?.customerName, 'Maria');
    });

    testWidgets('sem argumentos gera URI limpa, sem customerId=null', (
      tester,
    ) async {
      final captured = await _push(
        tester,
        (context) => WsNavigator.pushDeviceRegister(context),
      );

      expect(captured.uri.toString(), '/device/register');
      expect(captured.uri?.queryParameters, isEmpty);
      expect(captured.args?.customerId, isNull);
      expect(captured.args?.customerName, isNull);
    });
  });

  group('DeviceRegisterRouteArgs.fromRoute', () {
    test('lê customerId da query e customerName do extra', () {
      final args = DeviceRegisterRouteArgs.fromRoute(
        Uri.parse('/device/register?customerId=7'),
        const DeviceRegisterExtra(customerName: 'Ana'),
      );
      expect(args.customerId, 7);
      expect(args.customerName, 'Ana');
    });

    test('ignora customerName vindo da query string (deep-link legado)', () {
      final args = DeviceRegisterRouteArgs.fromRoute(
        Uri.parse('/device/register?customerId=7&customerName=Ana'),
        null,
      );
      expect(args.customerId, 7);
      expect(args.customerName, isNull);
    });

    test('extra de outro tipo e customerId inválido viram null', () {
      final args = DeviceRegisterRouteArgs.fromRoute(
        Uri.parse('/device/register?customerId=null'),
        'Ana',
      );
      expect(args.customerId, isNull);
      expect(args.customerName, isNull);
    });
  });
}
