import 'dart:ffi';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'log_sink.dart';
import 'rotating_file_sink.dart';

bool get _isDesktop =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

/// Rotating file sink under the app support directory (`%APPDATA%\...\logs`
/// on Windows); no-op on mobile.
Future<LogSink> createDefaultLogSink() async {
  if (!_isDesktop) return const NoopLogSink();
  final support = await getApplicationSupportDirectory();
  final dir = Directory('${support.path}${Platform.pathSeparator}logs');
  return RotatingFileSink(directory: dir);
}

String describePlatform() =>
    '${Platform.operatingSystem} (${Platform.operatingSystemVersion}), '
    'dart ${Platform.version.split(' ').first}';

bool get supportsLogDirectory => _isDesktop;

Future<bool> openDirectory(String path) async {
  if (!_isDesktop) return false;
  await Directory(path).create(recursive: true);
  if (Platform.isWindows) {
    // The folder window is drawn by the already running shell process, not by
    // a process we start, so Windows keeps it behind the app unless the app
    // (which owns the foreground) lets other processes take it.
    _allowAnyProcessToSetForeground();
    return launchUrl(Uri.directory(path, windows: true));
  }
  final result = await Process.run(Platform.isMacOS ? 'open' : 'xdg-open', [
    path,
  ]);
  return result.exitCode == 0;
}

/// Calls `AllowSetForegroundWindow(ASFW_ANY)`; best-effort, failures ignored.
void _allowAnyProcessToSetForeground() {
  try {
    final allow = DynamicLibrary.open('user32.dll')
        .lookupFunction<Int32 Function(Uint32), int Function(int)>(
          'AllowSetForegroundWindow',
        );
    const asfwAny = 0xFFFFFFFF;
    allow(asfwAny);
  } catch (_) {
    // Without it the folder still opens, possibly behind the app.
  }
}
