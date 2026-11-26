import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_workshop_front/app_route.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/pages/bootstrap_error/bootstrap_error_page.dart';
import 'package:flutter_workshop_front/pages/home/home_page.dart';
import 'package:flutter_workshop_front/pages/setup/setup_page.dart';
import 'package:flutter_workshop_front/pages/splash/splash_page.dart';

void main() {
  group('SplashPage and boot redirect', () {
    Widget buildTestApp(AuthNotifier authNotifier) {
      final router = buildRouter(
        authNotifier,
        routesOverride: [
          GoRoute(
            path: SplashPage.route,
            builder: (_, __) => const SplashPage(),
          ),
          GoRoute(
            path: HomePage.route,
            builder: (_, __) => const Scaffold(body: Text('HOME_PLACEHOLDER')),
          ),
          GoRoute(
            path: SetupPage.route,
            builder: (_, __) => const Scaffold(body: Text('SETUP_PLACEHOLDER')),
          ),
          GoRoute(
            path: BootstrapErrorPage.route,
            builder: (_, __) =>
                const Scaffold(body: Text('BOOTSTRAP_ERROR_PLACEHOLDER')),
          ),
        ],
      );

      return ChangeNotifierProvider<AuthNotifier>.value(
        value: authNotifier,
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets(
      'exibe SplashPage durante restoring e redireciona para home ao autenticar',
      (tester) async {
        final authNotifier = AuthNotifier(
          initialState: AuthRouteState.restoring,
        );
        final initCompleter = Completer<AuthRouteState>();

        await tester.pumpWidget(buildTestApp(authNotifier));
        await tester.pump();

        expect(find.byType(SplashPage), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Restaurando sessão...'), findsOneWidget);
        expect(find.text('HOME_PLACEHOLDER'), findsNothing);

        unawaited(
          initCompleter.future.then((state) => authNotifier.setState(state)),
        );
        initCompleter.complete(AuthRouteState.authenticated);

        await tester.pumpAndSettle();

        expect(find.byType(SplashPage), findsNothing);
        expect(find.text('HOME_PLACEHOLDER'), findsOneWidget);
      },
    );

    testWidgets(
      'redireciona de SplashPage para setup quando inicializacao retorna needsSetup',
      (tester) async {
        final authNotifier = AuthNotifier(
          initialState: AuthRouteState.restoring,
        );

        await tester.pumpWidget(buildTestApp(authNotifier));
        await tester.pump();
        expect(find.byType(SplashPage), findsOneWidget);

        authNotifier.setState(AuthRouteState.needsSetup);
        await tester.pumpAndSettle();

        expect(find.byType(SplashPage), findsNothing);
        expect(find.text('SETUP_PLACEHOLDER'), findsOneWidget);
      },
    );

    testWidgets(
      'redireciona de SplashPage para bootstrap-error quando inicializacao falha (offline ou storageError)',
      (tester) async {
        for (final errorState in [
          AuthRouteState.offline,
          AuthRouteState.storageError,
        ]) {
          final authNotifier = AuthNotifier(
            initialState: AuthRouteState.restoring,
          );

          await tester.pumpWidget(buildTestApp(authNotifier));
          await tester.pump();
          expect(find.byType(SplashPage), findsOneWidget);

          authNotifier.setState(errorState);
          await tester.pumpAndSettle();

          expect(find.byType(SplashPage), findsNothing);
          expect(find.text('BOOTSTRAP_ERROR_PLACEHOLDER'), findsOneWidget);
        }
      },
    );
    testWidgets(
      'nao gera overflow em SplashPage mesmo com viewport minimo 1x1 (primeiro frame desktop)',
      (tester) async {
        tester.view.physicalSize = const Size(1, 1);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: SplashPage()));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(SplashPage), findsOneWidget);
      },
    );
  });
}
