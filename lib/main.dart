import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_workshop_front/app_route.dart';
import 'package:flutter_workshop_front/core/agent/agent_toolkit.dart';
import 'package:flutter_workshop_front/core/config/app_config.dart';
import 'package:flutter_workshop_front/core/di/app_dependencies.dart';
import 'package:flutter_workshop_front/core/logging/app_logger.dart';
import 'package:flutter_workshop_front/core/logging/global_error_logging.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/core/security/secure_key_value_store.dart';
import 'package:flutter_workshop_front/pages/config_error/config_error_app.dart';
import 'package:flutter_workshop_front/repositories/catalog/catalog_repository.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/repositories/device/device_repository.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';
import 'package:flutter_workshop_front/widgets/core/ws_drawer/ws_drawer_controller.dart';

Future<void> main() => runWithAgentToolkit(_startApp);

Future<void> _startApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.init();
  installGlobalErrorLogging();
  unawaited(logAppStart());

  final AppConfig config;
  try {
    config = AppConfig.fromEnvironment();
  } on AppConfigException catch (e, st) {
    AppLogger.error(
      'Bootstrap',
      'Invalid build config',
      error: e,
      stackTrace: st,
    );
    runApp(ConfigErrorApp(message: e.message));
    return;
  }

  final deps = AppDependencies.create(
    config,
    const FlutterSecureKeyValueStore(),
  );
  final authNotifier = deps.authNotifier;
  authNotifier.setState(AuthRouteState.restoring, notify: false);
  try {
    if (config.resetStorageOnBoot) {
      await deps.storage.clearProvisioning();
      AppLogger.info('Bootstrap', 'Storage namespace reset');
    }
    await deps.authService.initializeAuthState();
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

  runApp(MyApp(router: router, deps: deps));
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  final AppDependencies deps;

  const MyApp({super.key, required this.router, required this.deps});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDependencies>.value(value: deps),
        Provider<DeviceRepository>.value(value: deps.deviceRepository),
        Provider<CustomerRepository>.value(value: deps.customerRepository),
        Provider<CatalogRepository>.value(value: deps.catalogRepository),
        ChangeNotifierProvider<AuthNotifier>.value(value: deps.authNotifier),
        Provider<AuthService>.value(value: deps.authService),
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
