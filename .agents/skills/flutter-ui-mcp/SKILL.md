---
name: flutter-ui-mcp
description: Dirige a UI do flutter-workshop-front em execução (Linux desktop ou web) com o mcp_flutter (flutter-mcp-toolkit), por Semantics identifier ou rótulo, com saída curta (ok/erro). Também roda os cenários repetíveis de integration_test contra a API local. Use para testar um fluxo de tela no app real, reproduzir um bug de UI, achar a origem de um overflow ou conferir uma mudança de front sem screenshot nem coordenada.
---

# Dirigir a UI com o mcp_flutter

## Regras
- Rode o app sem tela (abaixo): na tela do usuário, um clique dele muda o estado.
- Nunca imprima a API key nem leia configuração com `evaluate_dart_expression`. Para digitar uma chave, use `type-secret`.
- O logout (`drawer.logout`) apaga o setup salvo, sem confirmação.
- Não use `pkill -f`/`pgrep -f` com padrão que apareça no próprio comando (mata o seu shell); use os `*.pid`.

## Cenário repetível: integration_test
Os cenários do E2E do PR #61 (lista de clientes recarrega ao voltar do detalhe e do cadastro, validação bloqueia o envio, total de aparelhos some com 502, pickers de data) estão em `integration_test/`. Com a API local de pé (skill `e2e-local-api`, `up.sh`):
```bash
bash $SKILL/scripts/run_integration_tests.sh $STATE_E2E          # ou: ... $STATE_E2E integration_test/devices_test.dart
```
Imprime só `PASS`/`FAIL <teste> -- <motivo>` e o resumo; o log completo fica em `$STATE_E2E/itest.log`. Um cenário novo que vai se repetir entra ali, não no MCP. O MCP fica para explorar.

## Subir e conectar
```bash
DEFINES="--dart-define-from-file=$STATE_E2E/test-auth.env" \
  bash $SKILL/scripts/run_desktop_headless.sh $STATE   # em background; web: run_web_headless.sh
```
- Espere `$STATE/vm.txt` existir. Encerre com `kill $(cat $STATE/flutter.pid)`.
- `WINDOW` (padrão `1280x1000`) é o tamanho da janela; use `WINDOW=1280x720` para reproduzir telas baixas.
- O storage usa o namespace `agent` (`STORAGE_NAMESPACE`), separado do setup do dev, e a API key e os tokens dele são apagados no boot (`CLEAN_STORAGE=1`, padrão), então a chave de outro run nunca manda o app para o setup. Use `CLEAN_STORAGE=0` para manter a sessão entre runs da mesma API.

## Caminho padrão: `ui.py`
```bash
U() { python3 -I "$SKILL/scripts/ui.py" --vm "$STATE/vm.txt" "$@"; }
U tap drawer.customers            # ok | error: <código>: <detalhe>
U type customers.search "Silva"
U tap customer.card.1
U wait id=customerDetail.edit     # ou: U wait "Salvar" / U wait "Carregando" --gone
U snap --id customerDetail.       # árvore curta: ref, tipo, #identifier, "rótulo", =valor
U assert-text "Cliente Editado"; U assert-no-text "Por favor, insira um nome"
U type-secret label="API Key" DEV_API_KEY "$STATE_E2E/test-auth.env"
U errors                          # erros do app, com o widget de origem
U back; U key Escape
```
- Alvo: `id=<identifier>`, `label=<texto>` ou texto puro (identifier exato, depois rótulo exato, linha do rótulo e trecho único). Com vários, vence o que está na tela; senão vem `ambiguous` com os refs.
- Cada comando tira o snapshot, resolve o ref, rola o alvo para dentro da tela (pela distância certa) e só então age. Não guarde refs entre comandos.
- `tap` num container (card, botão com identifier) age no descendente que aceita tap; num texto dentro de um card, no card.
- Use as tools `fmt_*` (ou `scripts/fmtk.sh`) só para explorar o que o `ui.py` não cobre (`F snap`, screenshot, hot reload). Sem elas na sessão, leia `instructions/agents/flutter-ui-mcp.md` para instalar.

## Identifiers
Convenção `<página>.<elemento>`; com eles, `identifierPrefix`, `subtreeOf` e `wait_for node` funcionam, e uma ação não cai num campo homônimo de outra página.
- Menu: `drawer.home|customers|searchDevices|updates|logs|logout|toggle`.
- Busca: `customers.search`, `allDevices.search`, `searchDevices.search` (os dois primeiros têm o mesmo rótulo).
- Filtros: `allDevices.filterToggle`, `searchDevices.filterToggle`, `allDevices.filter.entryDate`, `searchDevices.filter.entryDate` (intervalo).
- Cliente: `customers.add`, `customer.card.<id>`, `customerDetail.edit|save|cancel`, `customerRegister.submit`.
- Aparelho: `device.card.<id>`, `deviceDetail.edit|save|cancel|entryDate|departureDate`, `deviceRegister.submit|cancel`.
Controle novo que um teste toca ganha `Semantics(identifier: ...)`; num botão o identifier fica num nó pai do botão, num campo de texto vai no próprio campo.

## Overflow e erros
Em debug, todo `FlutterError` sai inteiro no `run.log` (não só o primeiro), com "The relevant error-causing widget was" e o arquivo:linha. `U errors` mostra a primeira linha e o widget. Para achar a origem: `grep -n "overflowed by" -A6 $STATE/run.log`.

## Limites
- Não funcionam: `wait_for` `changed`; `navigate` `push` (go_router; navegue pela UI, `pop` funciona); `focus_window`.
- Campos de data são somente leitura e não têm a ação `tap`: o `ui.py` toca o centro do campo (nunca o botão de limpar dentro dele).
- Screenshot no Linux só com `mode`/`screenshotMode` `"flutter_layer"`.
- Estouram o limite de tokens: `hot_reload_and_capture`, `get_view_details`, `inspect_widget_at_point`. Use `hot_reload_flutter` e `get_screenshots`.
- Conexão perdida: `discover_debug_apps`. `hot_restart_flutter` volta ao Dashboard.

## Armadilhas do app
- CPF e telefone voltam `verified: false` (máscara): confira com `snap`.
- Dropdown Sexo: `U tap Sexo`, `U tap Masculino`.
- A chave fica presa ao primeiro dispositivo (`bound_device_id`, compartilhado entre namespaces): setup em outro alvo dá 409 `auth.api_key.device.bound`. Uma API nova (`up.sh`) resolve.
