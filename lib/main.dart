import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_workshop_front/app_route.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
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
