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
- O shell é zsh: comando guardado em variável não se divide em palavras e glob sem match aborta. Use funções (como `U`) e aspas.
- Os dados de cada cenário são seus: crie-os antes (skill `e2e-local-api`, "Dados do cenário"); o seed é só a base mínima.

## Cenário repetível: integration_test
Cenários que se repetem ficam em `integration_test/`. Com a API local de pé (skill `e2e-local-api`, `up.sh`):
```bash
bash $SKILL/scripts/run_integration_tests.sh $STATE_E2E          # ou: ... $STATE_E2E integration_test/devices_test.dart
```
Imprime só `PASS`/`FAIL <teste> -- <motivo>`; log completo em `$STATE_E2E/itest.log`. Cenário novo que vai se repetir entra ali; o MCP fica para explorar.

## Subir e conectar
```bash
DEFINES="--dart-define-from-file=$STATE_E2E/test-auth.env" \
  bash $SKILL/scripts/run_desktop_headless.sh $STATE   # em background; web: run_web_headless.sh
```
- Espere `$STATE/vm.txt` existir. Encerre com `kill $(cat $STATE/flutter.pid)`.
- `WINDOW` (padrão `1280x1000`) é o tamanho pedido; use `WINDOW=1280x720` para reproduzir telas baixas. Depois de subir, rode `U size`: mostra o viewport real e avisa `MISMATCH` se o gerenciador de janelas manteve outro tamanho. Julgue layout pelo viewport, que também abre a saída de todo `U snap`.
- `HEADED=1` roda na sessão Wayland do usuário (`$WAYLAND_DISPLAY`) em vez do KWin headless: o usuário vê a janela, mas um clique ou minimizar dele muda o estado. Use só quando pedirem.
- O storage usa o namespace `agent`, separado do setup do dev, e é limpo no boot. `CLEAN_STORAGE=0` mantém a sessão entre runs da mesma API.

## Caminho padrão: `ui.py`
```bash
U() { python3 -I "$SKILL/scripts/ui.py" --vm "$STATE/vm.txt" "$@"; }
U tap drawer.customers            # ok | error: <código>: <detalhe>
U type customers.search "Silva"
U tap customer.card.1
U wait id=customerDetail.edit     # ou: U wait "Salvar" / U wait "Carregando" --gone
U snap --id customerDetail.       # árvore curta: ref, tipo, #identifier, "rótulo", =valor
U assert-text "Cliente Editado"; U assert-no-text "Por favor, insira um nome"
U tap "Cadastrar Aparelho / Registrar novo aparelho para reparo"   # rótulo como o snap imprime
U type value="R\$ 0,00" 15000; U wait value="R\$ 150,00"   # campo sem rótulo, pelo valor
U tap ref=s_41                    # botão sem rótulo: ref do snap anterior, com a tela parada
U snap --under id=deviceDetail.entryDate   # só o nó e os filhos (aceita qualquer alvo)
U size                            # viewport real x WINDOW pedido
U type-secret label="API Key" DEV_API_KEY "$STATE_E2E/test-auth.env"
U errors                          # erros do app, com o widget de origem
U back; U key Escape
```
- Alvo: `id=<identifier>`, `label=<texto>`, `hint=`, `value=`, `ref=` ou texto puro (identifier, rótulo, depois hint). Com vários, vence o que está na tela; senão vem `ambiguous` com os refs. Texto puro nunca casa com o valor digitado de um campo: use `value=`. Neste app o hint do Material entra no rótulo (`"Buscar Cliente / Busque por um cliente"`), então `hint=` raramente acha algo. Espaços não separáveis (moeda, `R$\u00a00,00`) casam com espaço comum.
- Texto puro pode casar por substring com outro controle: `U tap Adicionar` abre "Adicionar Contato" porque o "Adicionar" de pagamento não tem rótulo na semântica. Confira no `snap` antes de tocar por texto curto.
- Cada comando tira o snapshot e rola o alvo para a tela antes de agir. `ref=` só vale logo depois do `snap` que o mostrou, com a tela parada; prefira `id=`. Não misture com refs das tools `fmt_*`, que vêm de outro snapshot.
- `type` foca o campo antes de digitar: um Autocomplete (Buscar Cliente) só mostra opções com o campo focado.
- Confirme o estado antes do próximo passo: depois de abrir ou fechar diálogo, picker ou menu, `U wait` pelo que deve aparecer (ou `--gone`). `U wait id=` espera dentro do app; os outros alvos repetem o `snap` com o mesmo matching do `tap`, então um `--gone` só prova algo se o alvo existia antes. Não encadeie toques às cegas nem use `sleep` fixo: um `Cancelar` mandado sem picker aberto cai no botão da página.
- Use as tools `fmt_*` (ou `scripts/fmtk.sh`) só para explorar o que o `ui.py` não cobre (screenshot, hot reload). Elas só conectam com o app subido com `VM_PORT=8181`. Sem elas na sessão, leia `instructions/agents/flutter-ui-mcp.md` para instalar.

## Identifiers
Convenção `<página>.<elemento>` (`drawer.customers`, `customer.card.<id>`, `deviceDetail.save`). Para listar: `U snap --id <página>.` na tela aberta. O grep (`grep -rn "identifier:" lib`) não mostra os montados por parâmetro (`semanticsIdentifier:`) nem quando o controle aparece (`deviceRegister.*` só depois de escolher o cliente).
- Plano de teste: tire os passos e identifiers de um `U snap` de cada tela no app rodando, não do grep nem da memória. Controle novo que um teste toca ganha `Semantics(identifier: ...)`; num botão fica num nó pai do botão, num campo de texto no próprio campo.

## Overflow e erros
`U errors [N]` mostra cada erro com o widget de origem, inclusive os seguintes ao primeiro. No `run.log`, hoje só o primeiro `FlutterError` sai inteiro ("The relevant error-causing widget was" + arquivo:linha); os seguintes viram "Another exception was thrown" (item aberto no backlog). Para o primeiro: `grep -n "overflowed by" -A6 $STATE/run.log`.

## Limites
- Não funcionam: `wait_for` `changed`; `navigate` `push` (go_router; navegue pela UI, `pop` funciona); `focus_window`.
- Campos de data são somente leitura e não têm a ação `tap`: o `ui.py` toca o centro do campo (nunca o botão de limpar dentro dele).
- Screenshot no Linux só com `mode`/`screenshotMode` `"flutter_layer"`. Por padrão a imagem vem comprimida (1280x720 vira 1024x576): para medir, use `compress: false` ou, melhor, `U size`.
- As tools `fmt_*` salvam screenshots em `.mcp_screenshots/` do diretório onde o servidor MCP subiu (em geral o checkout principal, fora do worktree): copie as que forem evidência para o `STATE`.
- Estouram o limite de tokens: `hot_reload_and_capture`, `get_view_details`, `inspect_widget_at_point`. Use `hot_reload_flutter` e `get_screenshots`.
- Conexão perdida: `discover_debug_apps`. `hot_restart_flutter` volta ao Dashboard.

## Armadilhas do app
- CPF e telefone voltam `verified: false` (máscara): confira com `snap`.
- Dropdown Sexo: `U tap Sexo`, `U tap Masculino`.
- A chave fica presa ao primeiro dispositivo (`bound_device_id`, compartilhado entre namespaces): setup em outro alvo dá 409 `auth.api_key.device.bound`. Uma API nova (`up.sh`) resolve.
