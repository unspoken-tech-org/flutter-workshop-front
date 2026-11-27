import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static architecture and test-hygiene guardrails for `flutter-workshop-front`.
///
/// Legacy violations are frozen in explicit baselines so new code cannot
/// introduce regressions while existing code is migrated incrementally.
void main() {
  final root = Directory.current;
  final libDir = Directory('${root.path}/lib');
  final testDir = Directory('${root.path}/test');

  setUpAll(() {
    expect(
      libDir.existsSync(),
      isTrue,
      reason: 'Expected lib/ directory at ${libDir.path}',
    );
    expect(
      testDir.existsSync(),
      isTrue,
      reason: 'Expected test/ directory at ${testDir.path}',
    );
  });

  group('Architecture guardrails', () {
    test(
      'lib/pages/ does not import services/ or package:dio/ (except AuthService and UpdateService)',
      () {
        const allowedServiceImports = <String>{
          'package:flutter_workshop_front/services/auth/auth_service.dart',
          'package:flutter_workshop_front/services/update/update_service.dart',
        };

        final violations = <String>[];
        for (final file in _dartFilesIn('${root.path}/lib/pages')) {
          final relPath = _relativePath(root, file);
          final content = file.readAsStringSync();
          for (final importUri in _extractImports(content)) {
            if (importUri == 'package:dio/dio.dart' ||
                importUri.startsWith('package:dio/')) {
              violations.add('$relPath -> $importUri');
              continue;
            }
            final isServiceImport =
                importUri.startsWith(
                  'package:flutter_workshop_front/services/',
                ) ||
                importUri.contains('/services/') ||
                importUri.startsWith('services/');
            if (isServiceImport && !allowedServiceImports.contains(importUri)) {
              violations.add('$relPath -> $importUri');
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Pages/controllers in lib/pages/ must depend on repositories, '
              'never services/ or package:dio/ directly (only AuthService and '
              'UpdateService are permitted exceptions).',
        );
      },
    );

    test(
      'fromEnvironment is restricted to AppConfig (and MCP_TOOLKIT in agent_toolkit.dart)',
      () {
        const allowedStringFromEnvFiles = <String>{
          'lib/core/config/app_config.dart',
        };
        const allowedBoolFromEnvFiles = <String>{
          'lib/core/config/app_config.dart',
          'lib/core/agent/agent_toolkit.dart',
        };

        final stringPattern = RegExp(r'\bString\.fromEnvironment\b');
        final boolPattern = RegExp(r'\bbool\.fromEnvironment\b');
        final intPattern = RegExp(r'\bint\.fromEnvironment\b');

        final violations = <String>[];
        for (final file in _dartFilesIn('${root.path}/lib')) {
          final relPath = _relativePath(root, file);
          final lines = file.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            final line = _stripLineComment(lines[i]);
            if (stringPattern.hasMatch(line) &&
                !allowedStringFromEnvFiles.contains(relPath)) {
              violations.add('$relPath:${i + 1} uses String.fromEnvironment');
            }
            if (boolPattern.hasMatch(line) &&
                !allowedBoolFromEnvFiles.contains(relPath)) {
              violations.add('$relPath:${i + 1} uses bool.fromEnvironment');
            }
            if (intPattern.hasMatch(line)) {
              violations.add('$relPath:${i + 1} uses int.fromEnvironment');
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Read build configuration only via AppConfig.fromEnvironment() '
              'in lib/core/config/app_config.dart.',
        );
      },
    );

    test(
      'every ChangeNotifier uses SafeChangeNotifierMixin (except frozen legacy baseline)',
      () {
        const legacyChangeNotifiersWithoutMixin = <String>{
          'lib/core/security/auth_notifier.dart:AuthNotifier',
          'lib/pages/customers/customer_detail/controllers/customer_detail_controller.dart:CustomerDetailController',
          'lib/pages/customers/customer_register/controllers/customer_register_controller.dart:CustomerRegisterController',
          'lib/pages/setup/setup_controller.dart:SetupController',
          'lib/widgets/core/ws_drawer/ws_drawer_controller.dart:WsDrawerController',
        };

        final classHeaderPattern = RegExp(
          r'class\s+(\w+)\s+([^{]*)\{',
          multiLine: true,
        );
        final changeNotifierPattern = RegExp(
          r'\b(?:extends|with)\b[^;]*\bChangeNotifier\b',
        );
        final safeMixinPattern = RegExp(r'\bSafeChangeNotifierMixin\b');

        final violations = <String>[];
        for (final file in _dartFilesIn('${root.path}/lib')) {
          final relPath = _relativePath(root, file);
          final content = file.readAsStringSync();
          for (final match in classHeaderPattern.allMatches(content)) {
            final className = match.group(1)!;
            final clauses = match.group(2)!;
            if (!changeNotifierPattern.hasMatch(clauses)) continue;
            if (safeMixinPattern.hasMatch(clauses)) continue;

            final key = '$relPath:$className';
            if (!legacyChangeNotifiersWithoutMixin.contains(key)) {
              violations.add(key);
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'New ChangeNotifier classes must mix in SafeChangeNotifierMixin.',
        );
      },
    );
  });

  group('UI feedback guardrails', () {
    test(
      'controllers, interceptors, services and core do not import SnackBarUtil',
      () {
        const snackBarImport =
            'package:flutter_workshop_front/utils/snackbar_util.dart';

        bool isNonUiLayer(String relPath) {
          if (relPath.startsWith('lib/core/') ||
              relPath.startsWith('lib/services/') ||
              relPath.startsWith('lib/repositories/')) {
            return true;
          }
          return relPath.startsWith('lib/pages/') &&
              (relPath.contains('/controller/') ||
                  relPath.contains('/controllers/'));
        }

        final violations = <String>[];
        for (final file in _dartFilesIn('${root.path}/lib')) {
          final relPath = _relativePath(root, file);
          if (!isNonUiLayer(relPath)) continue;
          if (_extractImports(
            file.readAsStringSync(),
          ).contains(snackBarImport)) {
            violations.add(relPath);
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Controllers and the HTTP layer publish a UiMessage '
              '(UiMessageSource / UiMessageBus); only pages and widgets show '
              'it, through UiMessageListener.',
        );
      },
    );

    test('only SnackBarUtil shows snackbars (no ScaffoldMessenger.of)', () {
      final violations = <String>[];
      for (final file in _dartFilesIn('${root.path}/lib')) {
        final relPath = _relativePath(root, file);
        if (relPath == 'lib/utils/snackbar_util.dart') continue;
        final source = file.readAsStringSync();
        if (source.contains('ScaffoldMessenger.of(') ||
            source.contains('.showSnackBar(')) {
          violations.add(relPath);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Show feedback with SnackBarUtil (widgets) or UiMessage '
            '(controllers) so every message has the same look.',
      );
    });
  });

  group('Test hygiene guardrails', () {
    test('no test file imports another *_test.dart file', () {
      final violations = <String>[];
      for (final file in _dartFilesIn('${root.path}/test')) {
        final relPath = _relativePath(root, file);
        final content = file.readAsStringSync();
        for (final importUri in _extractImports(content)) {
          if (importUri == 'package:flutter_test/flutter_test.dart') continue;
          if (importUri.endsWith('_test.dart')) {
            violations.add('$relPath -> $importUri');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Shared test helpers belong in test/support/, never imported from '
            'another *_test.dart file.',
      );
    });

    test(
      'no test overrides FlutterError.onError to ignore overflowed errors',
      () {
        final onErrorPattern = RegExp(r'FlutterError\.onError\s*=');
        final overflowPattern = RegExp(
          'overflow'
          'ed',
          caseSensitive: false,
        );

        final violations = <String>[];
        for (final file in _dartFilesIn('${root.path}/test')) {
          final relPath = _relativePath(root, file);
          if (relPath == 'test/architecture/architecture_test.dart') continue;

          final content = file.readAsStringSync();
          if (onErrorPattern.hasMatch(content) &&
              overflowPattern.hasMatch(content)) {
            violations.add(relPath);
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Do not silence overflowed errors in FlutterError.onError; fix the '
              'widget layout or configure a realistic surfaceSize in '
              'widget_test_harness.dart.',
        );
      },
    );
  });
}

List<File> _dartFilesIn(String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return const [];
  final files =
      dir
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return files;
}

String _relativePath(Directory root, File file) {
  final rootPath = root.path.replaceAll('\\', '/');
  final filePath = file.path.replaceAll('\\', '/');
  if (filePath.startsWith('$rootPath/')) {
    return filePath.substring(rootPath.length + 1);
  }
  return filePath;
}

Iterable<String> _extractImports(String content) {
  final importPattern = RegExp(
    r'''^\s*import\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );
  return importPattern.allMatches(content).map((m) => m.group(1)!);
}

String _stripLineComment(String line) {
  final index = line.indexOf('//');
  return index == -1 ? line : line.substring(0, index);
}
