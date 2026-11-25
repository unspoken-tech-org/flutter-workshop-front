import 'package:flutter_workshop_front/core/security/security_storage.dart';

import 'in_memory_secure_key_value_store.dart';

/// [SecurityStorage] real sobre [InMemorySecureKeyValueStore], com contadores
/// e injeção de erro para os testes de sessão.
///
/// Único fake de credenciais da suíte: não copie outro nos testes.
class MemorySecurityStorage extends SecurityStorage {
  factory MemorySecurityStorage({String boundDeviceIdFallback = 'device-1'}) =>
      MemorySecurityStorage._(
        InMemorySecureKeyValueStore(),
        boundDeviceIdFallback,
      );

  MemorySecurityStorage._(this._store, this.boundDeviceIdFallback)
    : super(_store);

  final InMemorySecureKeyValueStore _store;

  /// Devolvido por [getBoundDeviceId] quando não há id salvo (não persiste).
  final String boundDeviceIdFallback;

  /// Conteúdo atual (`api_key`, `access_token`, `refresh_token`,
  /// `bound_device_id`).
  Map<String, String> get values => _store.values;

  int clearSessionCalls = 0;
  int clearProvisioningCalls = 0;
  int saveAccessTokenCalls = 0;
  int saveTokensCalls = 0;
  int getAccessTokenCalls = 0;

  Object? Function(int callIndex)? getAccessTokenErrorOnCall;
  Object? clearProvisioningError;
  Object? getRefreshTokenError;
  Object? getApiKeyError;
  Object? getBoundDeviceIdError;

  void seedTokens({String? accessToken, String? refreshToken, String? apiKey}) {
    if (accessToken != null) values['access_token'] = accessToken;
    if (refreshToken != null) values['refresh_token'] = refreshToken;
    if (apiKey != null) values['api_key'] = apiKey;
  }

  @override
  Future<void> clearSession() {
    clearSessionCalls += 1;
    return super.clearSession();
  }

  @override
  Future<void> clearProvisioning({bool removeBoundDeviceId = false}) async {
    clearProvisioningCalls += 1;
    final error = clearProvisioningError;
    if (error != null) throw error;
    return super.clearProvisioning(removeBoundDeviceId: removeBoundDeviceId);
  }

  @override
  Future<String?> getAccessToken() {
    getAccessTokenCalls += 1;
    final error = getAccessTokenErrorOnCall?.call(getAccessTokenCalls);
    if (error != null) throw error;
    return super.getAccessToken();
  }

  @override
  Future<String?> getApiKey() {
    final error = getApiKeyError;
    if (error != null) throw error;
    return super.getApiKey();
  }

  @override
  Future<String?> getRefreshToken() {
    final error = getRefreshTokenError;
    if (error != null) throw error;
    return super.getRefreshToken();
  }

  @override
  Future<String> getBoundDeviceId() async {
    final error = getBoundDeviceIdError;
    if (error != null) throw error;
    return values['bound_device_id'] ?? boundDeviceIdFallback;
  }

  @override
  Future<void> saveAccessToken(String accessToken) {
    saveAccessTokenCalls += 1;
    return super.saveAccessToken(accessToken);
  }

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) {
    saveTokensCalls += 1;
    return super.saveTokens(accessToken, refreshToken);
  }
}
