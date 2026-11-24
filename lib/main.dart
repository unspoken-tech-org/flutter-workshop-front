import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_workshop_front/app_route.dart';
import 'package:flutter_workshop_front/core/agent/agent_toolkit.dart';
import 'package:flutter_workshop_front/core/config/config.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/core/logging/app_logger.dart';
import 'package:flutter_workshop_front/core/logging/global_error_logging.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/core/security/security_storage.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';
import 'package:flutter_workshop_front/widgets/core/ws_drawer/ws_drawer_controller.dart';

Future<void> main() => runWithAgentToolkit(_startApp);

Future<void> _startApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.init();
  installGlobalErrorLogging();
  unawaited(logAppStart());
  Config.validateBaseUrl(Config.baseUrl, isReleaseMode: kReleaseMode);

  // Inicialização da Camada de Segurança
  final authNotifier = AuthNotifier();
  final storage = SecurityStorage();
  final authService = AuthService(storage: storage, authNotifier: authNotifier);
  CustomDio.setup(
    storage,
    authService.refreshToken,
    authNotifier,
    onCredentialRejected: authService.forceLogout,
  );
  authNotifier.setState(AuthRouteState.restoring, notify: false);
  try {
    await authService.initializeAuthState();
  } catch (e, st) {
    debugPrint('[AuthDebug] Unexpected bootstrap error: $e\n$st');
    AppLogger.error(
      'Bootstrap',
      'Unexpected auth bootstrap error',
      error: e,
      stackTrace: st,
    );
    authNotifier.setState(AuthRouteState.storageError, notify: false);
  }
  final router = buildRouter(authNotifier);
  AppLogger.info(
    'Bootstrap',
    'Auth state restored: ${authNotifier.state.name}',
  );

  runApp(
    MyApp(router: router, authNotifier: authNotifier, authService: authService),
  );
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  final AuthNotifier authNotifier;
  final AuthService authService;

  const MyApp({
    super.key,
    required this.router,
    required this.authNotifier,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider(create: (_) => WsDrawerController()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: SnackBarUtil().scaffoldKey,
        routerConfig: router,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
      ),
    );
  }
}
