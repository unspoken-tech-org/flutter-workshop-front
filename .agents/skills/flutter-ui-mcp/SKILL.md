---
name: flutter-ui-mcp
description: Dirige a UI do flutter-workshop-front em execução (Linux desktop ou web) com o mcp_flutter (flutter-mcp-toolkit), lendo a tela pela árvore de semântica e agindo por refs (tap, digitação, formulários, espera, erros do app). Use para testar um fluxo de tela no app real, reproduzir um bug de UI ou conferir uma mudança de front sem depender de screenshot e coordenada. Rascunho: ainda será combinada com a skill e2e-local-api.
---

# Dirigir a UI com o mcp_flutter

O Flutter desenha num canvas, então navegador e leitores de DOM não enxergam os widgets. O mcp_flutter conecta na VM service do app (debug ou profile) e expõe a árvore de semântica: cada campo e botão aparece com tipo, rótulo e valor, e as ações usam o `ref` desse nó (`s_12`).

> **Status:** rascunho tirado do spike de 24/11/2026. A CLI e o servidor MCP foram validados no Linux desktop. Pelo Claude Code, o servidor ainda não foi testado.

## Regras
- Nunca imprima a API key. Leia de arquivo e passe por variável.
- Antes de concluir que a ferramenta falhou, confira se o valor que você digitou não está vazio (o `DEV_API_KEY` dos `.env-local` está vazio).
- Rode o app **sem tela** (seção 2). Na tela do usuário, um clique dele em outra janela muda foco e estado.
- Não use `pkill -f`/`pgrep -f` com um padrão que apareça no próprio comando: isso mata o seu shell (exit 144). Use `pgrep -f '[b]undle/flutter_workshop_front'` ou arquivos `*.pid`.
- `sleep` em primeiro plano é bloqueado: use `wait_for` (seção 4) ou `timeout N bash -c 'until …; do sleep 1; done'`.

## 1. Pré-requisitos
- **Flutter 3.47.9**, a versão do CI (o `mcp_toolkit` 8.x exige Flutter 3.44+). Se o `flutter` do PATH for mais antigo, use o fvm: `~/fvm/versions/3.47.9/bin/flutter`. Os scripts usam esse caminho quando ele existe.
- **Lado do app:** já está no código. `lib/core/agent/agent_toolkit.dart` envolve o `main` inteiro com o bootstrap do `mcp_toolkit` quando o app roda com `--dart-define=MCP_TOOLKIT=true`. Em release ele nunca liga.
- **CLI/servidor:** binários `flutter-mcp-toolkit` (CLI, alias `fmtk`) e `flutter-mcp-toolkit-server` (MCP) de [Arenukvern/mcp_flutter](https://github.com/Arenukvern/mcp_flutter). Instale pelo script oficial, com a versão fixa igual à do `mcp_toolkit` do `pubspec.yaml` (8.0.0). Ele baixa o asset `linux-x64` da release e confere o sha256:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/Arenukvern/mcp_flutter/v8.0.0/install.sh -o /tmp/fmtk-install.sh
  bash /tmp/fmtk-install.sh --version 8.0.0 --install-dir ~/.local/share/flutter-mcp-toolkit/bin
  ```
  - Os scripts desta skill procuram os binários nessa pasta. Para outra, defina `FMTK_BIN`.
  - O instalador acrescenta a pasta ao PATH no `.bashrc`/`.zshrc` (não no fish). A skill não depende do PATH.
  - O sha256 só confere com o `checksums.txt` da mesma release: não há assinatura.
  - Só existem binários para Linux x64 e macOS arm64. O servidor não está no pub.dev nem no npm.
- **Backend:** a API local com uma chave válida. Por enquanto, use a skill `e2e-local-api` para subir a API isolada e obter a chave.

## 2. Rodar o app sem tela

**Linux desktop** (validado): um KWin sem tela e o app dentro dele.
```bash
bash $SKILL/scripts/run_desktop_headless.sh $STATE   # em background
```
O script sobe `kwin_wayland --virtual --socket wayland-agent` (se ainda não existir), roda `flutter run -d linux` com `WAYLAND_DISPLAY=wayland-agent` e grava a URI da VM service em `$STATE/vm.txt`.

**Web** (validado): `flutter run -d web-server` mais um Chrome headless aberto à parte.
```bash
bash $SKILL/scripts/run_web_headless.sh $STATE   # em background
```
- A porta é a **3000**, porque o CORS da API local só aceita `localhost:3000`, `:8080` e `:8081`. Isso não se aplica se você usa o proxy da skill `e2e-local-api`, que responde o CORS.
- **Não funcionam:** `flutter run -d chrome --web-browser-flag=--headless=new` (*"Multiple targets are not supported in headless mode"*), nem Chrome normal dentro do KWin sem tela. Nesse caso a página fica `visible`, mas o `requestAnimationFrame` nunca dispara, e a tela não atualiza depois de digitar.

As variáveis de ambiente que os scripts usam:
- `FLUTTER`: binário do Flutter. Padrão: fvm 3.47.9 ou o `flutter` do PATH.
- `DEFINES`: padrão `--dart-define-from-file=.env-local`.
- `APP_DIR`: padrão o diretório atual.
- `VM_PORT`: porta fixa da VM service, sem código de autenticação. É o que o servidor MCP precisa (seção 7). Sem ela, a porta é aleatória e a URI fica em `$STATE/vm.txt`.

## 3. Conectar
```bash
F() { bash "$SKILL/scripts/fmtk.sh" "$STATE/vm.txt" "$@"; }   # função, não variável: o zsh não divide "$F"
F status
F snap        # resumo: ref, tipo, rótulo, valor, enabled
```
Nomes de uma letra em minúscula (`g`, `f`) podem colidir com aliases do shell.
O `fmtk.sh` é um atalho para `flutter-mcp-toolkit --vm-service-uri <uri> exec --name <comando> --args '<json>'`. A resposta é JSON: confira `"ok": true`. Em falha vem `"ok": false` com `error.code` e, em geral, `recovery.fix_command`.

Se a conexão falhar (`vm_not_connected`, por exemplo depois de um hot restart), `F discover_debug_apps` lista os apps em debug com a URI atual de cada um. O `fmtk doctor --json` não ajuda aqui: com a VM service sem código de autenticação (`VM_PORT`), ele acusa `vm_target_reachable: fail` mesmo com o app respondendo.

## 4. O ciclo: ler, agir, esperar, conferir
1. **Ler:** `F snap`, ou o JSON completo com `F semantic_snapshot '{}'`, que traz bounds e `center` de cada nó.
2. **Agir pelo ref:**
   ```bash
   F tap_widget '{"ref":"s_10"}'
   F enter_text '{"ref":"s_4","text":"..."}'
   F fill_form  '{"fields":[{"ref":"s_9","text":"Fulano"},{"ref":"s_10","text":"52998224725"}]}'
   ```
3. **Esperar** pela consequência, em vez de usar `sleep`:
   ```bash
   F wait_for '{"predicate":{"kind":"text","text":"Detalhes do Cliente"},"timeoutMs":8000}'
   ```
   Predicados: `text`, `noText`, `node` (com `identifier` e estado), `stable` (`stableWindowMs`), `noError` e `time`.
4. **Conferir:** `F snap` de novo, que mostra os valores dos campos e o `enabled` dos botões, e `F get_app_errors`. Para provar efeito no backend, consulte o banco ou a API.

**Refs mudam** depois de navegação, abertura de dropdown ou rebuild grande. Tire um novo `snap` antes de agir de novo.

A documentação do mcp_flutter oferece dois recursos para isso: passar `snapshotId` nas ações, para receber `stale_snapshot` quando a árvore mudou, e esperar com o predicado `changed`. **Pela CLI, nenhum dos dois funciona neste app:** um `tap_widget` com `snapshotId` antigo foi aceito depois de uma navegação, e `{"kind":"changed","since":N}` expirou mesmo com a tela mudando. Use `text`/`noText` e um `snap` novo.

## 5. Comandos úteis
| Comando | Para quê |
| --- | --- |
| `semantic_snapshot` | Árvore de semântica com refs. Aceita `fields`, `subtreeOf` e `identifierPrefix` |
| `tap_widget`, `long_press`, `hover`, `drag`, `swipe`, `scroll` | Gestos por ref |
| `enter_text`, `fill_form` | Digitação; devolve `verified` e `appliedText` |
| `reveal_search` | Rola até achar um nó fora da tela (`query`, `matchBy`: `identifier`, `label` etc., `direction`, `maxAttempts`) e devolve o `ref`. Precisa de uma lista rolável na tela; sem ela, `scroll_blocked` |
| `press_key`, `focus_widget` | Teclado e foco. Não há tecla "Back": use `navigate` com `pop` ou `press_key` `Escape` |
| `handle_dialog` | Fecha o diálogo do topo (`{"action":"dismiss"}`) |
| `navigate` | Só `{"action":"pop"}` funciona. `push` falha com `push_rejected`, porque o app usa go_router e o Navigator não tem rotas nomeadas. Navegue pela UI |
| `wait_for` | Espera por condição |
| `get_app_errors`, `get_recent_logs` | Erros e logs do app |
| `get_screenshots`, `capture_ui_snapshot` | Imagem da tela |
| `hot_reload_flutter`, `hot_restart_flutter` | Recarregar depois de editar código |
| `hot_reload_and_capture` | Hot reload e screenshot numa chamada (`{"includeErrors":true}`). Pela CLI o PNG vem em base64 no JSON: redirecione para arquivo |
| `evaluate_dart_expression` | Avaliar Dart no app (desktop; no web depende do DWDS) |

A lista completa sai de `flutter-mcp-toolkit capabilities` e os argumentos de `flutter-mcp-toolkit schema`.

## 6. Armadilhas conhecidas neste app
- **Campos com máscara** (CPF, telefone) voltam com `verified: false`, porque o valor final é o formatado (`529.982.247-25`). Confira `appliedText` em vez de tratar isso como falha.
- **Botões só com ícone** (menu lateral, logout) aparecem como `button`/`tappable` sem rótulo. Ache pelo `center`/bounds no `semantic_snapshot` completo. O logout é o último item à esquerda, com `center.y` acima de 670 numa janela de 1280x720.
- **Dropdown de Sexo:** `tap_widget` no botão `Sexo`, novo `snap` e tap no item (`Masculino`, `Feminino`, `Outro`).
- **Setup:** o botão `Conectar ao Servidor` só fica `enabled` com texto no campo. Logo depois do setup, o app vai para `Dashboard Aparelhos`.
- **Chave presa a um dispositivo:** depois do setup num alvo (desktop), o setup em outro (web) recebe 409 `auth.api_key.device.bound`. No banco local, limpe `bound_device_id`/`bound_at` da chave.
- **Logout:** volta para a tela de setup sem confirmação. É o caminho mais curto para testar o setup de novo.

## 7. Servidor MCP
O mesmo catálogo existe como servidor MCP (`flutter-mcp-toolkit-server`). Ele conecta num host e numa porta, sem o código da URI, então o app precisa subir com porta fixa:
```bash
VM_PORT=8181 bash $SKILL/scripts/run_desktop_headless.sh $STATE   # em background
claude mcp add flutter-ui -s local -- "$FMTK_BIN/flutter-mcp-toolkit-server" \
  --dart-vm-host=localhost --dart-vm-port=8181 --save-images --idle-exit-minutes=60
```
- `-s local` deixa a configuração só na sua máquina. O caminho do binário muda de pessoa para pessoa, por isso o servidor não vai no `.mcp.json` do repositório.
- `--save-images` grava os screenshots em arquivo, em vez de devolver base64 no contexto.
- As tools têm prefixo `fmt_` (`fmt_semantic_snapshot`, `fmt_tap_widget`, `fmt_fill_form`, `fmt_wait_for` etc.) e aceitam os mesmos argumentos da CLI.
- As tools só aparecem numa sessão nova do Claude Code. Confira com `claude mcp list`.
- `--disable-service-auth-codes` deixa a VM service aberta a qualquer processo local na porta 8181. Use só em máquina de desenvolvimento.

O servidor respondeu pelo protocolo MCP (stdio) com o app em 8181, mas ainda não foi usado de dentro de uma sessão do Claude Code. Se as tools não aparecerem, use a CLI desta skill.

**Plugin oficial (alternativa, não usado aqui):** `/plugin marketplace add Arenukvern/mcp_flutter` e `/plugin install flutter-mcp-toolkit@flutter-mcp-toolkit`. Ele não instala o binário: o servidor continua vindo do `install.sh`. Também registra o próprio servidor MCP, que duplica as tools se o `claude mcp add` acima também estiver ativo. E traz 16 skills genéricas, algumas de manutenção do próprio mcp_flutter, que concorrem com esta. Use o plugin ou esta seção, nunca os dois.

## 8. Tools do próprio app (ainda não usado)
O `mcp_toolkit` deixa o app registrar tools e resources próprios, que o agente chama por `fmt_list_client_tools_and_resources`, `fmt_client_tool` e `fmt_client_resource`. Pode servir, por exemplo, para expor a rota atual do go_router ou navegar direto para ela, já que o `navigate` não funciona com go_router. Se for usar:
- Registre com `MCPToolkitBinding.instance.addEntries(entries: {AgentCallEntry.tool(...)})` em `lib/core/agent/agent_toolkit.dart`, antes do `bootstrapFlutter`. Assim continua só com `MCP_TOOLKIT=true` e fora do release.
- Use namespace e nome próprios em `snake_case` (`workshop_…`). Se o nome colidir com uma tool nativa, a sua é ignorada sem aviso.
- Nunca devolva chave, token ou dado de cliente: as regras do `AppLogger` valem aqui.
- Na 8.0.0, registrar de novo o mesmo nome depois de um hot reload pode manter o handler antigo. Faça hot restart.
- Receitas em `plugin/skills/flutter-mcp-toolkit-custom-tools/SKILL.md` do repositório do mcp_flutter.

## 9. Encerrar
Mate o `flutter run` (e o Chrome headless no web) pelos PIDs gravados em `$STATE`. O KWin sem tela pode ficar para a próxima execução, ou `kill $(cat $STATE/kwin.pid)`.
