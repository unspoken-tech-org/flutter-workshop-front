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
import 'package:flutter_workshop_front/services/auth/auth_service.dart';

import '../../support/fakes/fake_auth_service.dart';

void main() {
  group('BootstrapErrorPage', () {
    testWidgets(
      'exibe mensagem de offline e aciona retry e reconfiguracao de chave',
      (tester) async {
        final authNotifier = AuthNotifier(initialState: AuthRouteState.offline);
        final authService = FakeAuthService(authNotifier: authNotifier);
        final completer = Completer<AuthRouteState>();
        authService.onInitializeAuthState = () => completer.future;

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
              Provider<AuthService>.value(value: authService),
            ],
            child: const MaterialApp(home: BootstrapErrorPage()),
          ),
        );

        expect(find.text('Sem conexão com o servidor'), findsOneWidget);
        expect(find.text('Tentar novamente'), findsOneWidget);
        expect(find.text('Configurar outra chave'), findsOneWidget);

        await tester.tap(find.text('Tentar novamente'));
        await tester.pump();

        expect(authService.initializeCalls, 1);
        expect(find.text('Tentando...'), findsOneWidget);

        completer.complete(AuthRouteState.offline);
        await tester.pumpAndSettle();

        expect(find.text('Tentar novamente'), findsOneWidget);

        await tester.tap(find.text('Configurar outra chave'));
        await tester.pump();

        expect(authNotifier.state, AuthRouteState.needsSetup);
      },
    );

    testWidgets('exibe mensagem especifica para storageError', (tester) async {
      final authNotifier = AuthNotifier(
        initialState: AuthRouteState.storageError,
      );
      final authService = FakeAuthService(authNotifier: authNotifier);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
            Provider<AuthService>.value(value: authService),
          ],
          child: const MaterialApp(home: BootstrapErrorPage()),
        ),
      );

      expect(find.text('Erro ao acessar credenciais'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.text('Configurar outra chave'), findsOneWidget);
    });
  });

  group('GoRouter redirects for AuthRouteState', () {
    test('resolveAuthRedirect cobre todos os estados de AuthRouteState', () {
      // restoring: redireciona tudo para /splash
      expect(
        resolveAuthRedirect(AuthRouteState.restoring, HomePage.route),
        SplashPage.route,
      );
      expect(
        resolveAuthRedirect(AuthRouteState.restoring, SetupPage.route),
        SplashPage.route,
      );
      expect(
        resolveAuthRedirect(AuthRouteState.restoring, BootstrapErrorPage.route),
        SplashPage.route,
      );
      expect(
        resolveAuthRedirect(AuthRouteState.restoring, SplashPage.route),
        isNull,
      );

      // needsSetup: redireciona tudo exceto /setup
      expect(
        resolveAuthRedirect(AuthRouteState.needsSetup, HomePage.route),
        SetupPage.route,
      );
      expect(
        resolveAuthRedirect(
          AuthRouteState.needsSetup,
          BootstrapErrorPage.route,
        ),
        SetupPage.route,
      );
      expect(
        resolveAuthRedirect(AuthRouteState.needsSetup, SetupPage.route),
        isNull,
      );

      // offline e storageError: redirecionam tudo exceto /bootstrap-error
      for (final state in [
        AuthRouteState.offline,
        AuthRouteState.storageError,
      ]) {
        expect(
          resolveAuthRedirect(state, HomePage.route),
          BootstrapErrorPage.route,
        );
        expect(
          resolveAuthRedirect(state, SetupPage.route),
          BootstrapErrorPage.route,
        );
        expect(resolveAuthRedirect(state, BootstrapErrorPage.route), isNull);
      }

      // authenticated: tira de /splash, /setup e /bootstrap-error, libera rotas do app
      expect(
        resolveAuthRedirect(AuthRouteState.authenticated, SplashPage.route),
        HomePage.route,
      );
      expect(
        resolveAuthRedirect(AuthRouteState.authenticated, SetupPage.route),
        HomePage.route,
      );
      expect(
        resolveAuthRedirect(
          AuthRouteState.authenticated,
          BootstrapErrorPage.route,
        ),
        HomePage.route,
      );
      expect(
        resolveAuthRedirect(AuthRouteState.authenticated, HomePage.route),
        isNull,
      );
      expect(
        resolveAuthRedirect(AuthRouteState.authenticated, '/device/all'),
        isNull,
      );
    });

    testWidgets('GoRouter navega reativamente para todos os estados de auth', (
      tester,
    ) async {
      final authNotifier = AuthNotifier(initialState: AuthRouteState.restoring);
      final authService = FakeAuthService(authNotifier: authNotifier);
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
            builder: (_, __) => const BootstrapErrorPage(),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
            Provider<AuthService>.value(value: authService),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      // 1. restoring: exibe SplashPage em /splash
      expect(find.byType(SplashPage), findsOneWidget);

      // 2. offline -> /bootstrap-error com BootstrapErrorPage
      authNotifier.setState(AuthRouteState.offline);
      await tester.pumpAndSettle();
      expect(find.byType(BootstrapErrorPage), findsOneWidget);
      expect(find.text('Sem conexão com o servidor'), findsOneWidget);

      // 3. needsSetup -> /setup
      authNotifier.setState(AuthRouteState.needsSetup);
      await tester.pumpAndSettle();
      expect(find.text('SETUP_PLACEHOLDER'), findsOneWidget);

      // 4. storageError -> /bootstrap-error
      authNotifier.setState(AuthRouteState.storageError);
      await tester.pumpAndSettle();
      expect(find.byType(BootstrapErrorPage), findsOneWidget);
      expect(find.text('Erro ao acessar credenciais'), findsOneWidget);

      // 5. authenticated -> volta para /home
      authNotifier.setState(AuthRouteState.authenticated);
      await tester.pumpAndSettle();
      expect(find.text('HOME_PLACEHOLDER'), findsOneWidget);
    });
  });
}
