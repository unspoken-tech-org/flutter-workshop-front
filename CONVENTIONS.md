# Convenções de Arquitetura e Testes — flutter-workshop-front

Este documento registra as convenções obrigatórias para código novo e revisões de PR em `flutter-workshop-front/`. Regras executáveis estão travadas em [test/architecture/architecture_test.dart](test/architecture/architecture_test.dart) e rodam automaticamente no `flutter test`.

---

## 1. Convenções de Arquitetura

1. **Fronteira `lib/pages/` -> repositórios:** páginas e controllers em `lib/pages/` dependem de repositórios (`DeviceRepository`, `CustomerRepository`, `CatalogRepository`), nunca de `services/` ou `package:dio/` diretamente.
   - **Exceções permitidas (`AGENTS.md`):** `AuthService` e `UpdateService` (hoje em `bootstrap_error_page.dart`, `setup_controller.dart`, `setup_page.dart` e `home_page.dart`).
   - **Por quê:** manter desacoplamento de transporte HTTP e tratamento uniforme de `Result<T>` / `AppFailure`.
2. **Configuração de build centralizada:** `String.fromEnvironment` só pode ser chamado em `AppConfig.fromEnvironment()` (`lib/core/config/app_config.dart`). `bool.fromEnvironment('MCP_TOOLKIT')` em `lib/core/agent/agent_toolkit.dart` é a única exceção de flag de tooling.
   - **Por quê:** validação única no boot com fallback para `ConfigErrorApp`.
3. **`SafeChangeNotifierMixin` obrigatório:** todo novo `ChangeNotifier` em `lib/` deve usar `with SafeChangeNotifierMixin` (referência: `HomeController`, `DeviceRegisterController`, `DeviceCustomerPageController`, `AllDevicesController`).
   - **Baseline congelada (legado):** `AuthNotifier`, `AllCustomerController`, `CustomerDetailController`, `CustomerRegisterController`, `SearchDevicesController`, `SetupController` e `WsDrawerController` estão congelados na baseline de `architecture_test.dart` até sua migração.

---

## 2. Convenções Obrigatórias de Testes

1. **Espelhamento 1:1 e zero arquivos soltos:** todo arquivo `*_test.dart` em `test/` espelha o caminho do alvo em `lib/` (exceto `test/architecture/`). Proibido `*_test.dart` na raiz de `test/` ou em pastas paralelas fora de `lib/` (como `test/auth/`, `test/setup/`, `test/integration/`).
2. **Proibido importar outro `*_test.dart`:** código compartilhado (adapters HTTP, fakes, fixtures, helpers de pump) vive exclusivamente em `test/support/`.
3. **HTTP via `StubHttpClientAdapter` e fakes explícitos (sem `noSuchMethod` silencioso):** para testar camadas sobre `Dio`, usar `Dio` real com `StubHttpClientAdapter` (`test/support/http/stub_http_client_adapter.dart`) — nunca `class MockDio implements Dio` com `noSuchMethod`. Fakes de repositório/serviço estendem `Fake` do `flutter_test` (falhando rápido em métodos inesperados) e retornam `Ok(...)` / `Err(AppFailure)` diretamente — proibido usar `result_guard.dart` em testes novos.
4. **Fixtures tipadas:** construir modelos de domínio via `test/support/fixtures/` (ex.: `device_customer_fixture.dart`) com parâmetros nomeados e defaults sensatos — nunca copiar blocos `fromJson({...})` de 20+ linhas em novos testes.
5. **Sem vazamento de estado global:** toda mutação de `tester.view.physicalSize`, `tester.view.devicePixelRatio`, `FlutterError.onError`, `AppLogger` (`minLevel`, `mirrorToConsole`, sink) ou `MethodChannel` **deve** ser restaurada em `addTearDown` / `tearDown` / `tearDownAll` (preferencialmente via `test/support/widget_test_harness.dart`).
6. **Proibido silenciar `overflowed` em `FlutterError.onError`:** se um widget dá overflow no teste, ajustar o `surfaceSize` realista no harness (ex.: `1920x1080` para desktop) ou corrigir o layout do widget.
7. **Sem `Future.delayed` / `runAsync` arbitrário:** proibido esperar tempo de relógio real (`Future.delayed(250ms/500ms)`) em novos testes unitários ou de widget — usar `Completer`, `tester.pump(duration)` ou clock/debouncer injetável.
8. **Finders estáveis em widget tests:** para interagir com botões, campos e controles em testes novos ou tocados, preferir `find.bySemanticsIdentifier('<page>.<element>')` (com `tester.ensureSemantics()` via harness) em vez de `find.byType(...)` genérico; reservar `find.text(...)` para validar mensagens/conteúdo visível ao usuário.
9. **Toda asserção é explícita:** proibido teste "smoke" que apenas chama um método sem `expect(...)` verificando o efeito observável (retorno, estado do storage, payload enviado ou transição de estado).
10. **Testes por comportamento, não por PR:** nomear arquivos pelo sujeito testado (`<controller_ou_widget>_test.dart`) e organizar cenários em `group(...)` por operação/fluxo — evitar nomes de bug/PR soltos.

---

## 3. O Que Não Copiar (Legado)

- **Não copiar** `InheritedAllCustomerController` (`InheritedWidget`/`InheritedNotifier`) — usar `ChangeNotifierProvider` + `SafeChangeNotifierMixin`.
- **Não copiar** `MethodChannel('dev.fluttercommunity.plus/package_info')` em testes de `AuthService` — injetar `appVersion` pelo construtor.
- **Não copiar** `result_guard.dart` em novos testes ou fakes — retornar `Ok(...)` / `Err(AppFailure)` diretamente.
