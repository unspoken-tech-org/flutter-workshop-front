import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/config/config.dart';
import 'package:flutter_workshop_front/main.dart' as app;

/// Boots the real app (`main`) against the local E2E API and runs [body].
///
/// The app installs its own `FlutterError.onError` (chained to the test
/// binding's, so overflows still fail the test); it is restored at the end,
/// as the test framework requires.
Future<void> bootApp(
  WidgetTester tester,
  Future<void> Function(WidgetTester tester) body,
) async {
  final flutterOnError = FlutterError.onError;
  final platformOnError = PlatformDispatcher.instance.onError;
  // Semantics identifiers (find.bySemanticsIdentifier) need the tree on.
  final semantics = tester.ensureSemantics();
  try {
    await app.main();
    await pumpUntil(tester, find.byType(MaterialApp));
    await pumpUntilFound(tester, find.bySemanticsIdentifier('drawer.home'));
    await body(tester);
  } finally {
    await setProxyMode('pass');
    FlutterError.onError = flutterOnError;
    PlatformDispatcher.instance.onError = platformOnError;
    semantics.dispose();
  }
}

/// Pumps frames in real time until [finder] matches (or vanishes, with
/// [gone]). `pumpAndSettle` never settles while a shimmer is running.
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  bool gone = false,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (true) {
    await tester.pump(const Duration(milliseconds: 50));
    final found = finder.evaluate().isNotEmpty;
    if (found != gone) return;
    if (DateTime.now().isAfter(deadline)) {
      throw TestFailure(
        'Timed out waiting for ${gone ? 'absence of ' : ''}$finder',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

Future<void> pumpUntilFound(WidgetTester tester, Finder finder) =>
    pumpUntil(tester, finder);

Future<void> pumpUntilGone(WidgetTester tester, Finder finder) =>
    pumpUntil(tester, finder, gone: true);

/// Lets in-flight requests finish without waiting on a specific widget.
Future<void> settleFor(WidgetTester tester, Duration duration) async {
  final deadline = DateTime.now().add(duration);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 50));
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

/// Lets a route transition or an expanding panel finish before a tap, so the
/// tap position is not computed on a widget that is still moving.
const _transition = Duration(milliseconds: 400);

Finder byId(String identifier) => find.bySemanticsIdentifier(identifier);

/// The editable text of the field with Semantics [identifier] or with the
/// decoration [label] (`labelText`).
Finder field({String? identifier, String? label}) {
  final Finder owner = identifier != null
      ? byId(identifier)
      : find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label,
          description: 'TextField labelled "$label"',
        );
  return find.descendant(of: owner, matching: find.byType(EditableText)).first;
}

String fieldText(WidgetTester tester, Finder editable) =>
    tester.widget<EditableText>(editable).controller.text;

Future<void> tapId(WidgetTester tester, String identifier) async {
  final target = byId(identifier);
  await pumpUntilFound(tester, target);
  await settleFor(tester, _transition);
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await tester.pump();
}

Future<void> tapText(WidgetTester tester, String text) async {
  final target = find.text(text).last;
  await pumpUntilFound(tester, target);
  await settleFor(tester, _transition);
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await tester.pump();
}

Future<void> enter(WidgetTester tester, Finder editable, String text) async {
  await pumpUntilFound(tester, editable);
  await tester.ensureVisible(editable);
  await tester.enterText(editable, text);
  await tester.pump();
}

/// Switches the E2E proxy (`e2e_proxy.py`) to [mode]: `pass` or `502`.
Future<void> setProxyMode(String mode) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse('${Config.baseUrl}/__e2e/mode/$mode'),
    );
    final response = await request.close();
    await response.drain<void>();
    if (response.statusCode != 200) {
      throw StateError('proxy mode $mode: ${response.statusCode}');
    }
  } finally {
    client.close();
  }
}

final _random = Random();

/// A run-unique tag of lowercase letters, so repeated runs against the same
/// database never clash (a numeric term would be searched as CPF/ID/phone).
String uniqueTag() {
  var n = DateTime.now().microsecondsSinceEpoch + _random.nextInt(1000);
  final letters = StringBuffer();
  for (var i = 0; i < 8; i++) {
    letters.writeCharCode(0x61 + n % 26);
    n ~/= 26;
  }
  return letters.toString();
}

/// A valid, random CPF (digits only).
String randomCpf() {
  final digits = List.generate(9, (_) => _random.nextInt(10));
  for (var round = 0; round < 2; round++) {
    var sum = 0;
    for (var i = 0; i < digits.length; i++) {
      sum += digits[i] * (digits.length + 1 - i);
    }
    final rest = (sum * 10) % 11;
    digits.add(rest == 10 ? 0 : rest);
  }
  return digits.join();
}

/// A random mobile number (digits only, DDD 11).
String randomPhone() =>
    '119${List.generate(8, (_) => _random.nextInt(10)).join()}';

/// Lines of the E2E proxy log (`E2E_PROXY_LOG`, set by
/// `run_integration_tests.sh`) that start with [prefix], or `null` when the
/// log is not available.
int? proxyRequests(String prefix) {
  final path = Platform.environment['E2E_PROXY_LOG'];
  if (path == null || !File(path).existsSync()) return null;
  return File(
    path,
  ).readAsLinesSync().where((line) => line.startsWith(prefix)).length;
}
