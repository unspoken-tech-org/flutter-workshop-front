import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_logger.dart';

void _dumpFullDebugError(FlutterErrorDetails details) {
  FlutterError.dumpErrorToConsole(details, forceReport: true);
}

/// Replaces Flutter's debug error presenter with one that always dumps the full
/// error details (including "The relevant error-causing widget was") instead of
/// collapsing subsequent errors to "Another exception was thrown".
///
/// On non-web debug builds, `WidgetsFlutterBinding.ensureInitialized()` sets
/// [FlutterError.presentError] to `WidgetInspectorService._reportStructuredError`,
/// whose private `_errorsSinceReload` counter is not reset by
/// [FlutterError.resetErrorCount]. Call this after binding initialization and
/// before any wrapper (such as `mcp_toolkit`'s `ErrorMonitor`) captures
/// [FlutterError.onError].
void configureVerboseDebugFlutterErrors() {
  if (!kDebugMode) return;
  final previousPresentError = FlutterError.presentError;
  FlutterError.presentError = _dumpFullDebugError;
  if (FlutterError.onError == previousPresentError) {
    FlutterError.onError = _dumpFullDebugError;
  }
}

/// Records uncaught framework and platform errors in the log file, chaining
/// to whatever handlers were installed before (presentation, crash reports).
///
/// In debug every [FlutterError] reaches the console in full (with the
/// "relevant error-causing widget" location), not only the first one: both the
/// default console dumper and `WidgetInspectorService._reportStructuredError`
/// collapse errors after the first into "Another exception was thrown", which
/// hides the source of a `RenderFlex overflow`.
void installGlobalErrorLogging() {
  configureVerboseDebugFlutterErrors();
  final previousFlutterHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    if (kDebugMode) {
      FlutterError.resetErrorCount();
    }
    AppLogger.error(
      'FlutterError',
      'Uncaught framework error'
          '${details.library == null ? '' : ' in ${details.library}'}'
          '${details.context == null ? '' : ' (${details.context})'}',
      error: details.exception,
      stackTrace: details.stack,
    );
    if (previousFlutterHandler != null) {
      previousFlutterHandler(details);
    } else {
      FlutterError.presentError(details);
    }
  };

  final dispatcher = PlatformDispatcher.instance;
  final previousPlatformHandler = dispatcher.onError;
  dispatcher.onError = (error, stack) {
    AppLogger.error(
      'PlatformDispatcher',
      'Uncaught async error',
      error: error,
      stackTrace: stack,
    );
    // Returning false keeps the engine's default reporting.
    return previousPlatformHandler?.call(error, stack) ?? false;
  };
}

/// Logs the app version, build mode and OS once at startup.
Future<void> logAppStart({
  Future<PackageInfo> Function() packageInfoLoader = PackageInfo.fromPlatform,
}) async {
  var version = 'unknown';
  try {
    final info = await packageInfoLoader();
    version = info.buildNumber.isEmpty
        ? info.version
        : '${info.version}+${info.buildNumber}';
  } catch (_) {
    // Version is informative only; log the start anyway.
  }
  const mode = kReleaseMode
      ? 'release'
      : kProfileMode
      ? 'profile'
      : 'debug';
  AppLogger.info(
    'App',
    'Started version=$version mode=$mode os=${AppLogger.describePlatform()}',
  );
}
