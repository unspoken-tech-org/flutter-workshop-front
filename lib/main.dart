import 'package:auto_updater/auto_updater.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_workshop_front/app_route.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/core/security/security_storage.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialização da Camada de Segurança
  final storage = SecurityStorage();
  final authService = AuthService(storage: storage);
  CustomDio.setup(storage, authService.refreshToken);

  if (kReleaseMode) {
    String feedURL =
        'https://github.com/unspoken-tech-org/flutter-workshop-front/releases/latest/download/appcast.xml';
    await autoUpdater.setFeedURL(feedURL);
    await autoUpdater.checkForUpdates();
    await autoUpdater.setScheduledCheckInterval(3600);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: SnackBarUtil().scaffoldKey,
      routerConfig: router,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
    );
  }
}
