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
/// `AppDependencies`: nenhuma outra classe lê `String.fromEnvironment`.
@immutable
class AppConfig {
  const AppConfig._({
    required this.baseUri,
    required this.devApiKey,
    required this.updateFeedUrl,
    required this.githubOwner,
    required this.githubRepo,
  });

  /// Origem da API, já validada (ver [validateBaseUrl]).
  final Uri baseUri;

  /// Chave de provisionamento automático; vazia fora do debug.
  final String devApiKey;

  /// Feed de releases alternativo (testes do updater); vazio usa o GitHub.
  final String updateFeedUrl;
  final String githubOwner;
  final String githubRepo;

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
    required bool isReleaseMode,
    bool isDebugMode = false,
  }) {
    return AppConfig._(
      baseUri: validateBaseUrl(baseUrl, isReleaseMode: isReleaseMode),
      // Só existe em debug: num build release a chave nunca é usada.
      devApiKey: isDebugMode ? devApiKey.trim() : '',
      updateFeedUrl: updateFeedUrl.trim(),
      githubOwner: githubOwner.trim(),
      githubRepo: githubRepo.trim(),
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
