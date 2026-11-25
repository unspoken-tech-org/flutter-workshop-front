import 'package:flutter_workshop_front/core/security/secure_key_value_store.dart';

/// [SecureKeyValueStore] em memória, compartilhado pelos testes.
class InMemorySecureKeyValueStore implements SecureKeyValueStore {
  InMemorySecureKeyValueStore([Map<String, String>? initial])
    : values = {...?initial};

  /// Conteúdo atual, por chave (`api_key`, `access_token`, ...).
  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> deleteAll() async => values.clear();
}
