import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_workshop_front/app_route.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/core/security/security_storage.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Inicialização da Camada de Segurança
  final authNotifier = AuthNotifier();
  final storage = SecurityStorage();
  final authService = AuthService(
    storage: storage,
    authNotifier: authNotifier,
  );
  CustomDio.setup(storage, authService.refreshToken, authNotifier);
  authNotifier.setState(AuthRouteState.restoring, notify: false);
  await authService.initializeAuthState();
  final router = buildRouter(authNotifier);

  runApp(
    MyApp(
      router: router,
      authNotifier: authNotifier,
      authService: authService,
    ),
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
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: SnackBarUtil().scaffoldKey,
        routerConfig: router,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [
          Locale('pt', 'BR'),
        ],
      ),
    );
  }
}
