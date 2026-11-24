---
name: flutter-ui-mcp
description: Dirige a UI do flutter-workshop-front em execução (Linux desktop ou web) com o mcp_flutter (flutter-mcp-toolkit), lendo a tela pela árvore de semântica e agindo por refs (tap, digitação, formulários, espera, erros do app). Use para testar um fluxo de tela no app real, reproduzir um bug de UI ou conferir uma mudança de front sem depender de screenshot e coordenada. Rascunho: ainda será combinada com a skill e2e-local-api.
---

# Dirigir a UI com o mcp_flutter

## Regras
- Rode o app sem tela (abaixo): na tela do usuário, um clique dele muda o estado.
- Nunca imprima a API key nem leia configuração com `evaluate_dart_expression`.
- O logout (último ícone do menu lateral) apaga o setup salvo, sem confirmação.
- Não use `pkill -f`/`pgrep -f` com padrão que apareça no próprio comando (mata o seu shell); use os `*.pid`.

## Subir e conectar
```bash
VM_PORT=8181 bash $SKILL/scripts/run_desktop_headless.sh $STATE   # em background; web: run_web_headless.sh
```
Espere `$STATE/vm.txt` existir. O app precisa de backend (skill `e2e-local-api`). Encerre com `kill $(cat $STATE/flutter.pid)`.

Use as tools `mcp__flutter-ui__fmt_*`. Sem elas na sessão, use a CLI (`F <tool sem fmt_> '<json>'`) e só então leia `instructions/agents/flutter-ui-mcp.md` se precisar instalar:
```bash
F() { bash "$SKILL/scripts/fmtk.sh" "$STATE/vm.txt" "$@"; }   # F snap = resumo da tela
```

## Ciclo
1. `semantic_snapshot` com `fields: ["ref","type","label","value","enabled"]`. Guarde o `snapshot_id`.
2. Aja pelo ref com `snapshotId` (`tap_widget`, `enter_text`, `fill_form`). Se a tela mudou, vem `stale_snapshot`: tire outro snapshot.
3. Espere com `wait_for` (`text`, `noText`, `stable`, `noError`), que devolve um snapshot novo.
4. Confira os valores no snapshot e `get_app_errors`.

## Limites
- Não funcionam: `wait_for` `changed`; `node`/`identifierPrefix` (o app não tem `identifier`); `navigate` `push` (go_router; navegue pela UI, `pop` funciona); `focus_window`.
- `scroll`, `swipe`, `reveal_search` precisam do `ref` de um nó `scrollable` (o Dashboard tem, o formulário de cliente não).
- Screenshot no Linux só com `mode`/`screenshotMode` `"flutter_layer"`.
- Estouram o limite de tokens: `hot_reload_and_capture`, `get_view_details`, `inspect_widget_at_point`. Use `hot_reload_flutter` e `get_screenshots`.
- Conexão perdida: `discover_debug_apps`. `hot_restart_flutter` volta ao Dashboard e reinicia o `snapshot_id`.

## Armadilhas do app
- CPF e telefone voltam `verified: false` (máscara): confira `appliedText`.
- Ícones do menu lateral não têm rótulo: ache pelo `center`.
- Dropdown Sexo: tap no botão, snapshot, tap no item, depois `wait_for` `{"kind":"stable","stableWindowMs":300}` (o snapshot vem vazio durante a animação). `handle_dialog` `dismiss` fecha o menu.
- A chave fica presa ao primeiro dispositivo: setup em outro alvo dá 409 `auth.api_key.device.bound`.
