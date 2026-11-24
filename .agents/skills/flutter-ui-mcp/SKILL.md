---
name: flutter-ui-mcp
description: Dirige a UI do flutter-workshop-front em execução (Linux desktop ou web) com o mcp_flutter (flutter-mcp-toolkit), lendo a tela pela árvore de semântica e agindo por refs (tap, digitação, formulários, espera, erros do app). Use para testar um fluxo de tela no app real, reproduzir um bug de UI ou conferir uma mudança de front sem depender de screenshot e coordenada. Rascunho: ainda será combinada com a skill e2e-local-api.
---

# Dirigir a UI com o mcp_flutter

As tools leem a árvore de semântica do app em debug: cada campo e botão vem com tipo, rótulo, valor e um `ref` (`s_12`), que é o alvo das ações. Instalação e registro do servidor MCP: `instructions/agents/flutter-ui-mcp.md`.

## Regras
- Rode o app **sem tela** (abaixo). Na tela do usuário, um clique dele muda foco e estado.
- Nunca imprima a API key nem leia configuração com `evaluate_dart_expression`.
- O logout (último ícone do menu lateral, `center.y` > 670) apaga o setup salvo, sem confirmação. Toque nele só para testar o setup de novo.
- Não use `pkill -f`/`pgrep -f` com padrão que apareça no próprio comando (mata o seu shell). Use `pgrep -f '[b]undle/flutter_workshop_front'` ou os `*.pid`.
- `sleep` em primeiro plano é bloqueado: espere com `wait_for` ou `timeout N bash -c 'until …; do sleep 1; done'`.

## 1. Subir o app
Em background, a partir da raiz do repositório:
```bash
VM_PORT=8181 bash $SKILL/scripts/run_desktop_headless.sh $STATE   # Linux desktop (KWin sem tela)
VM_PORT=8181 bash $SKILL/scripts/run_web_headless.sh $STATE       # web (porta 3000 + Chrome headless)
```
Espere `$STATE/vm.txt` existir. `VM_PORT=8181` é a porta que o servidor MCP espera. Outras variáveis estão no cabeçalho dos scripts (`FLUTTER`, `DEFINES`, `APP_DIR`). O app precisa de backend: use a skill `e2e-local-api`. Sem backend ele abre, mas as chamadas falham.

## 2. Conectar
- **MCP (preferido):** tools `mcp__flutter-ui__fmt_*`. Se não estiverem na sessão, veja as instruções de setup.
- **CLI (alternativa):** mesmos comandos e argumentos, sem o prefixo `fmt_`:
  ```bash
  F() { bash "$SKILL/scripts/fmtk.sh" "$STATE/vm.txt" "$@"; }
  F snap                                  # resumo: ref, tipo, rótulo, valor, enabled
  F tap_widget '{"ref":"s_10"}'           # JSON: confira "ok": true
  ```
Conexão perdida (por exemplo depois de um hot restart): `discover_debug_apps`.

## 3. O ciclo: ler, agir, esperar, conferir
1. **Ler:** `semantic_snapshot` com `fields` (`["ref","type","label","value","enabled"]`) para uma resposta curta. Guarde o `snapshot_id`.
2. **Agir pelo ref**, passando `snapshotId`: `tap_widget`, `enter_text`, `fill_form`. Se a tela mudou desde o snapshot, a ação falha com `stale_snapshot` em vez de agir num ref velho.
3. **Esperar** a consequência com `wait_for`: `{"kind":"text","text":"Cadastro de Cliente"}`, `noText`, `stable` (`stableWindowMs`), `noError`. Ele devolve um snapshot novo.
4. **Conferir:** valores e `enabled` no snapshot, e `get_app_errors`. Para efeito no backend, consulte a API ou o banco.

Refs mudam a cada navegação, abertura de menu ou rebuild grande: tire outro snapshot antes de agir de novo.

## 4. O que não funciona ou exige cuidado
- **`wait_for` com `changed`:** sempre expira. **`node` por `identifier`** e **`identifierPrefix`:** voltam vazios, porque o app não define `Semantics(identifier:)`.
- **`navigate`:** só `{"action":"pop"}`. `push` falha (`push_rejected`), porque o app usa go_router. Navegue tocando na UI.
- **`scroll`, `swipe`, `reveal_search`:** precisam do `ref` de um nó `scrollable`. O Dashboard tem um, o formulário de cliente não.
- **Screenshots (`get_screenshots`, `capture_ui_snapshot`):** no Linux, só com `mode` (ou `screenshotMode`) `"flutter_layer"`. O arquivo sai em `.mcp_screenshots/`, no diretório do servidor.
- **Respostas enormes**, que estouram o limite de tokens: `hot_reload_and_capture` (PNG em base64), `get_view_details`, `inspect_widget_at_point`. Prefira `hot_reload_flutter` seguido de `get_screenshots`.
- **`focus_window`:** só macOS e iOS. Não existe tecla "Back": use `navigate` `pop`, `handle_dialog` `dismiss` ou `press_key` `Escape`.
- **`hot_restart_flutter`:** reconecta sozinho, volta o app para o Dashboard e reinicia o `snapshot_id` em 1.

## 5. Armadilhas deste app
- **CPF e telefone** voltam `verified: false`, porque o campo formata o valor. Confira `appliedText` (`529.982.247-25`).
- **Botões só com ícone** (menu lateral) vêm sem rótulo: ache pelo `center` no snapshot com `fields` incluindo `center`.
- **Dropdown Sexo:** tap no botão `Sexo`, snapshot, tap no item. Logo depois o snapshot vem vazio (animação): espere `{"kind":"stable","stableWindowMs":300}`. `handle_dialog` `dismiss` fecha o menu aberto.
- **Setup:** `Conectar ao Servidor` só habilita com texto no campo e leva ao `Dashboard Aparelhos`. A chave fica presa ao primeiro dispositivo: setup em outro alvo dá 409 `auth.api_key.device.bound`.

## 6. Encerrar
`kill $(cat $STATE/flutter.pid)` (no web o script fecha o Chrome) e, se quiser, `kill $(cat $STATE/kwin.pid)`.
