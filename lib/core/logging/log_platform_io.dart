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
    // ShellExecute (via url_launcher) lets the shell bring the folder window to
    // the foreground. Spawning explorer.exe directly hands the window off to
    // the shell process without foreground rights, so it stays hidden until
    // Explorer is focused from the taskbar.
    return launchUrl(Uri.directory(path, windows: true));
  }
  final result = await Process.run(Platform.isMacOS ? 'open' : 'xdg-open', [
    path,
  ]);
  return result.exitCode == 0;
}
