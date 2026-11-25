import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Valores de build via --dart-define(-from-file); nenhum arquivo .env entra no bundle.
class Config {
  static String get baseUrl => const String.fromEnvironment('BASE_URL');

  static String get apiKey => const String.fromEnvironment('API_KEY');

  // Só existe em debug: num build release a chave nunca entra no binário.
  static String get devApiKey =>
      kDebugMode ? const String.fromEnvironment('DEV_API_KEY') : '';

  /// Só em debug: prefixo das chaves do secure storage. Runs de agente/E2E
  /// (`run_desktop_headless.sh`, `run_integration_tests.sh`) usam um
  /// namespace próprio para não ler nem sobrescrever o setup do dev, que
  /// divide o mesmo keyring.
  static String get storageNamespace =>
      kDebugMode ? const String.fromEnvironment('STORAGE_NAMESPACE') : '';

  /// Só em debug e só com [storageNamespace]: apaga a API key e os tokens do
  /// namespace no boot, para o app não reaproveitar a chave de outro run. O
  /// `bound_device_id` não tem namespace e fica (a chave se prende a ele).
  static bool get resetStorageOnBoot =>
      storageNamespace.isNotEmpty &&
      const bool.fromEnvironment('RESET_STORAGE');

  /// Hosts aceitos com `http://` fora do release (E2E local contra a API).
  static const _localHttpHosts = {'localhost', '127.0.0.1'};

  /// Valida o `BASE_URL` no boot e falha rápido com [StateError].
  ///
  /// Em release exige `https://`; em debug/profile aceita também
  /// `http://localhost` e `http://127.0.0.1` (`scripts/set_env.sh local`).
  static Uri validateBaseUrl(String rawUrl, {required bool isReleaseMode}) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      throw StateError(
        'BASE_URL ausente: rode com --dart-define-from-file=.env (ver .env.example).',
      );
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw StateError(
        'BASE_URL inválida: use uma URL absoluta http(s) com host.',
      );
    }

    if (uri.scheme == 'https') {
      return uri;
    }

    if (isReleaseMode) {
      throw StateError('BASE_URL deve usar https:// em builds release.');
    }

    if (!_localHttpHosts.contains(uri.host)) {
      throw StateError(
        'BASE_URL com http:// só é aceita para localhost/127.0.0.1 fora do release.',
      );
    }

    return uri;
  }

  static Future<String> get appVersion async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}
