import 'log_sink.dart';

/// Web/unsupported fallback: no file logging.
Future<LogSink> createDefaultLogSink() async => const NoopLogSink();

String describePlatform() => 'web';

bool get supportsLogDirectory => false;

Future<bool> openDirectory(String path) async => false;
