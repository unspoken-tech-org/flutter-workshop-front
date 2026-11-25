import 'package:flutter/foundation.dart';

/// Lido quando o `--dart-define(-from-file)` traz um valor inválido.
class AppConfigException implements Exception {
  const AppConfigException(this.message);

  final String message;

  @override
  String toString() => 'AppConfigException: $message';
}

/// Configuração de build, lida e validada uma única vez no boot.
///
/// Os valores vêm de `--dart-define(-from-file)`; nenhum arquivo `.env` entra
/// no bundle. A instância é criada no `main` e injetada pelo
/// `AppDependencies`: nenhuma outra classe lê `String.fromEnvironment`
/// (exceção: `MCP_TOOLKIT`, constante para o tree shaking do toolkit).
@immutable
class AppConfig {
  const AppConfig._({
    required this.baseUri,
    required this.devApiKey,
    required this.updateFeedUrl,
    required this.githubOwner,
    required this.githubRepo,
    required this.storageNamespace,
    required this.resetStorageOnBoot,
  });

  /// Origem da API, já validada (ver [validateBaseUrl]).
  final Uri baseUri;

  /// Chave de provisionamento automático; vazia fora do debug.
  final String devApiKey;

  /// Feed de releases alternativo (testes do updater); vazio usa o GitHub.
  final String updateFeedUrl;
  final String githubOwner;
  final String githubRepo;

  /// Só em debug: prefixo das chaves do secure storage. Runs de agente/E2E
  /// (`run_desktop_headless.sh`, `run_integration_tests.sh`) usam um
  /// namespace próprio para não ler nem sobrescrever o setup do dev, que
  /// divide o mesmo keyring.
  final String storageNamespace;

  /// Só em debug e só com [storageNamespace]: apaga a API key e os tokens do
  /// namespace no boot, para o app não reaproveitar a chave de outro run. O
  /// `bound_device_id` não tem namespace e fica (a chave se prende a ele).
  final bool resetStorageOnBoot;

  /// Hosts aceitos com `http://` fora do release (E2E local contra a API).
  static const _localHttpHosts = {'localhost', '127.0.0.1'};

  /// Lê os `--dart-define` do build e valida.
  ///
  /// Lança [AppConfigException] com uma mensagem acionável se algo faltar.
  factory AppConfig.fromEnvironment() {
    return AppConfig.fromValues(
      baseUrl: const String.fromEnvironment('BASE_URL'),
      devApiKey: const String.fromEnvironment('DEV_API_KEY'),
      updateFeedUrl: const String.fromEnvironment('UPDATE_FEED_URL'),
      githubOwner: const String.fromEnvironment('GITHUB_OWNER'),
      githubRepo: const String.fromEnvironment('GITHUB_REPO'),
      storageNamespace: const String.fromEnvironment('STORAGE_NAMESPACE'),
      resetStorage: const bool.fromEnvironment('RESET_STORAGE'),
      isReleaseMode: kReleaseMode,
      isDebugMode: kDebugMode,
    );
  }

  /// Valida valores crus; usado pelo [AppConfig.fromEnvironment] e por testes.
  factory AppConfig.fromValues({
    required String baseUrl,
    String devApiKey = '',
    String updateFeedUrl = '',
    String githubOwner = '',
    String githubRepo = '',
    String storageNamespace = '',
    bool resetStorage = false,
    required bool isReleaseMode,
    bool isDebugMode = false,
  }) {
    final namespace = isDebugMode ? storageNamespace.trim() : '';
    return AppConfig._(
      baseUri: validateBaseUrl(baseUrl, isReleaseMode: isReleaseMode),
      // Só existe em debug: num build release a chave nunca é usada.
      devApiKey: isDebugMode ? devApiKey.trim() : '',
      updateFeedUrl: updateFeedUrl.trim(),
      githubOwner: githubOwner.trim(),
      githubRepo: githubRepo.trim(),
      storageNamespace: namespace,
      resetStorageOnBoot: namespace.isNotEmpty && resetStorage,
    );
  }

  /// Valida o `BASE_URL` e falha com [AppConfigException].
  ///
  /// Em release exige `https://`; em debug/profile aceita também
  /// `http://localhost` e `http://127.0.0.1` (`scripts/set_env.sh local`).
  static Uri validateBaseUrl(String rawUrl, {required bool isReleaseMode}) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      throw const AppConfigException(
        'BASE_URL ausente: rode com --dart-define-from-file=.env (ver .env.example).',
      );
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw const AppConfigException(
        'BASE_URL inválida: use uma URL absoluta http(s) com host.',
      );
    }

    if (uri.scheme == 'https') {
      return uri;
    }

    if (isReleaseMode) {
      throw const AppConfigException(
        'BASE_URL deve usar https:// em builds release.',
      );
    }

    if (!_localHttpHosts.contains(uri.host)) {
      throw const AppConfigException(
        'BASE_URL com http:// só é aceita para localhost/127.0.0.1 fora do release.',
      );
    }

    return uri;
  }
}
