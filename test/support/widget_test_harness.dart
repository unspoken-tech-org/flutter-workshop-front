import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Configura o viewport de teste para desktop e restaura no teardown.
void configureDesktopTestViewport(
  WidgetTester tester, {
  Size size = const Size(1920, 1080),
  double devicePixelRatio = 1.0,
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Monta [child] dentro de um [MaterialApp] com viewport desktop restaurável.
Future<void> pumpAppWidget(
  WidgetTester tester,
  Widget child, {
  Size surfaceSize = const Size(1920, 1080),
  double devicePixelRatio = 1.0,
}) async {
  configureDesktopTestViewport(
    tester,
    size: surfaceSize,
    devicePixelRatio: devicePixelRatio,
  );
  await tester.pumpWidget(MaterialApp(home: child));
}
