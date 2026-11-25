---
name: e2e-local-api
description: Teste E2E manual do flutter-workshop-front contra a workshop_rest_api local, isolada (containers e2e-local-*, Postgres sintético em tmpfs, proxy que injeta 403/400/502). Use para validar no app real uma mudança de front que depende da API (auth, setup, pagamentos, aparelhos, contatos), testar vários PRs juntos ou reproduzir falhas de rede/gateway. Não usar contra PRD/QA.
---

# E2E local: front Flutter + API

Sobe a API a partir do HEAD do repo `workshop_rest_api`, sem tocar no checkout dela nem no banco de dev. Roda o app com `--dart-define-from-file` e o dirige pelo navegador embutido. Tudo o que é criado tem o prefixo `e2e-local-` e sai com `down.sh`.

## Regras
- Nunca use o compose `workshop_rest_api`, o `apps/api/compose/local.yml`, o banco de dev, PRD ou QA. Nada de ssh/tailscale.
- Nunca leia nem imprima o `.env` do checkout principal, nem a API key gerada. A chave só circula por arquivo (`test-auth.env`).
- Arquivos temporários ficam no scratchpad da sessão (`STATE`).
- `sleep` em primeiro plano é bloqueado: espere com `timeout N bash -c 'until …; do sleep 2; done'`.
- O shell é zsh: variável com comando (`P="docker exec ..."; $P`) não se divide em palavras e glob sem match (`--include=*.java`) aborta o comando. Use função ou script e ponha aspas no glob.
- Não use `pkill -f`/`pgrep -f` com um padrão que apareça no próprio comando, porque isso mata o seu shell (exit 144). Use os arquivos `*.pid`.
- Na limpeza, nunca rode `docker builder prune`: ele apaga o cache de build da máquina inteira.

## 1. Subir a API isolada
```bash
SKILL=<dir desta skill>; STATE=<scratchpad>/e2e
bash $SKILL/scripts/up.sh /home/ornelas/Documentos/repositorios/workshop-fe-be/workshop_rest_api $STATE
```
O que o script faz:
- **Código da API:** `git archive HEAD` copiado para `$STATE/api-src`, e o build da imagem `e2e-local-api:local` sai dessa cópia (reutilizada automaticamente enquanto o `HEAD` da API não mudar; passe `E2E_REBUILD=1` para forçar rebuild). Para testar outro branch da API, troque `HEAD` no script.
- **Banco:** Postgres `16.15-alpine3.24` em tmpfs. Sem `--user`, porque com ele o initdb falha.
- **API:** perfil `qa`. A senha do banco entra via configtree e as chaves JWT de dev do repo ficam em `/app/config/qa_keys`.
- **Seed:** a API key sintética vem do `seed.sql` do projeto (role ADMIN). `scripts/seed_reference.sql` é só a base mínima e um exemplo de inserts: 1 técnico, tipo/marca/modelo, cor, cliente com telefone e o aparelho #1 com status `NOVO`. Não o amplie para um plano: os dados de cada cenário vêm da seção "Dados do cenário".
- **Proxy de falhas:** fica numa porta fixa. É ele que o app usa como `BASE_URL`, e ele também responde o CORS do Flutter web.
- **Arquivos gerados:** `$STATE/test.env` (sem chave), `$STATE/test-auth.env` (com `DEV_API_KEY`), `$STATE/proxy.log` e `$STATE/state.env`.

Para saber mais sobre o schema:
- Colunas e tipos: `bash $SKILL/scripts/sql.sh --schema devices` (sem tabela, lista as tabelas). Consulte antes de escrever SQL; não adivinhe nomes (`payments` não tem `value`) nem tipos (`entry_date` é timestamp: `+ interval '1 day'`).
- Tabelas: `api_keys`, `technicians`, `types`, `brands`, `models`, `brands_models_types`, `colors`, `customers`, `phones`, `customer_phones`, `devices`, `customer_contact`, `payments`, `refresh_tokens`.
- Status do aparelho: `NOVO`, `EM_ANDAMENTO`, `AGUARDANDO`, `ENTREGUE`, `DESCARTADO`, `APROVADO`, `NAO_APROVADO`, `PRONTO`.
- Rotas: as de negócio são `/v1/...` e as de auth são `/api/auth/{token,refresh,revoke}`.

### Dados do cenário
Antes de cada cenário, crie o que ele precisa e anote no relatório como criou:
- **Pela UI** quando criar o dado também exercita um fluxo (cadastrar cliente/aparelho, trocar status pelo chip, registrar pagamento).
- **Por SQL** (`sql.sh`) quando o dado é só pré-condição: aparelho `ENTREGUE` com `departure_date`, vários aparelhos para um filtro ter o que excluir, status que aceita pagamento de serviço (`NOVO` recusa).
- Um filtro ou contagem só prova algo com dados que ele deveria excluir: crie pelo menos um aparelho fora do critério.

## 2. Rodar o app
Cenários que se repetem (recarga da lista de clientes, validação, total com 502, pickers de data) já estão em `integration_test/`: rode `bash .agents/skills/flutter-ui-mcp/scripts/run_integration_tests.sh $STATE`, que imprime só PASS/FAIL. Para dirigir o Linux desktop à mão, use a skill `flutter-ui-mcp` (`run_desktop_headless.sh` + `ui.py`).

```bash
WP=$(python3 -c "import socket;s=socket.socket();s.bind(('127.0.0.1',0));print(s.getsockname()[1])")
flutter run -d web-server --web-hostname 127.0.0.1 --web-port $WP --dart-define-from-file=$STATE/test.env   # em background
```
- Espere `Quit (terminate` aparecer no log antes de abrir `http://127.0.0.1:$WP` no navegador (via subagente `browser` ou `preview_start`).
- Com `test.env` (sem chave), o app abre em `/setup`. Use para testar uma chave inválida (ou com espaços nas pontas para validar `trim()`), digitando o valor no campo.
- Com `test-auth.env`, o app autentica sozinho em debug. Para trocar de env, encerre o `flutter run`: mate o processo cujo `ps -eo pid,args` contém `web-port $WP`, filtrando com awk e `[w]eb-port` para não pegar o próprio shell. Depois rode de novo.
- **Viewports obrigatórios:** valide em desktop (`1280×900` ou `1440×900`) **e** em viewport compacto (`1024×700`) — usando `resize_window` ou redimensionamento no subagente `browser`, e devolvendo `preset: desktop` ao fim se aplicável. No viewport compacto, confira explicitamente:
  - menus/overlays (ex.: `DeviceStatusChip`) inteiramente visíveis dentro da tela sem cortar à direita ou embaixo;
  - campos de data/moeda sem truncamento crítico;
  - FAB e botões flutuantes sem cobrir controles ou totais;
  - zero `RenderFlex overflow` no console.

### Particularidades do navegador com Flutter web
- **O screenshot pode mostrar o frame anterior.** Espere 1–2 s ou faça um `hover` antes de capturar de novo.
- **Autocomplete exige passo a passo:** clique, espera, digitação, espera, screenshot e clique na sugestão. Em lote rápido, os eventos se perdem.
- **O primeiro clique num botão às vezes só tira o foco** do campo; confira e clique de novo.
- **`onDoubleTap` não dispara** com o `double_click` do CDP, porque o Flutter exige ≥40 ms entre os toques. Use JS com coordenadas do viewport (as de screenshot × fator de escala):
  ```js
  const x=752,y=640,t=document.elementFromPoint(x,y),sl=m=>new Promise(r=>setTimeout(r,m));
  const f=(ty,b)=>t.dispatchEvent(new PointerEvent(ty,{bubbles:true,clientX:x,clientY:y,pointerId:1,pointerType:'mouse',button:0,buttons:b,isPrimary:true}));
  f('pointerdown',1);await sl(60);f('pointerup',0);await sl(120);f('pointerdown',1);await sl(60);f('pointerup',0);
  ```
- **Evidência no console:** capture mensagens do console (`read_console_messages` com `pattern` substring, ou console do Playwright/browser). Use `AuthDebug` e `GlobalError` para auth, e `EXCEPTION` ou `setState` para asserts de widget.

## 3. Injetar falhas
```bash
. $STATE/state.env
curl -s http://127.0.0.1:$PROXY_PORT/__e2e/mode/403html     # /v1/* -> 403 HTML (WAF)
curl -s http://127.0.0.1:$PROXY_PORT/__e2e/mode/refresh400  # /v1/* -> 401; /api/auth/refresh -> 400 "Gateway: Invalid Host Header"
curl -s http://127.0.0.1:$PROXY_PORT/__e2e/mode/502         # /v1/* -> 502 HTML (gateway), auth passa
curl -s http://127.0.0.1:$PROXY_PORT/__e2e/mode/pass
bash $SKILL/scripts/api_restart.sh $STATE down   # API fora do ar: o proxy devolve 502
bash $SKILL/scripts/api_restart.sh $STATE up     # religa a API e reaponta o proxy (a porta publicada da API muda)
```
- Para provocar novas requisições, navegue entre telas (Clientes ↔ Home).
- Depois de cada falha, volte a `pass` e confira que o app recupera **sem** novo `POST /api/auth/token` no `proxy.log`.

## 4. Coletar evidências
- **`$STATE/proxy.log`:** método, caminho, status e modo de cada requisição, sem headers nem corpo. Prova o que foi enviado e o que voltou.
- **Banco**, para confirmar persistência ou rejeição: `bash $SKILL/scripts/sql.sh "select ... from devices where id=N"`.
- **Corpo de uma resposta:** inspecione as requisições de rede (via `read_network_requests` ou rede do Playwright/browser).
- **Screenshot** de cada passo/falha, e console para exceções.
- Monte o relatório por cenário: passou/falhou, a evidência e, quando algo não pôde ser testado, o motivo e como validar depois.

## Cenários de referência
- **Setup:**
  - Chave inválida: espera 401 → erro no campo, continua em `/setup`.
  - Chave válida com espaços/quebras nas pontas: deve fazer `trim()` e autenticar com 200 → `/home`.
- **Pagamento (validação e rejeição):**
  - `"Recebido por"` é obrigatório na UI (sem `"Opcional"`) e bloqueia envio vazio.
  - Data futura é bloqueada no `CustomDateFormField` (dias futuros desabilitados no picker).
  - Erro da API (ex.: modo de falha ou validação backend): exibe toast **acima** do diálogo, mantém diálogo aberto e nenhuma linha em `payments`.
- **Orçamento e `"Valor a ser pago"`:**
  - No cadastro, "Valor Orçamento" vai para `budget_fee`; na edição, "Valor do serviço" vai para `service_value`.
  - "1.500,00" deve virar `1500.00`. Campo vazio deve virar `0.00`, sem erro.
  - Em edição, alterar o rascunho de `Valor do serviço` sem salvar não altera `"Valor a ser pago"` no card `Pagamentos` (mostra só o valor persistido).
- **Aparelho (`Status chip` e `departureDate`):**
  - `DeviceStatusChip` abre o menu por **clique/toque** (sem depender de hover) e mantém todas as opções visíveis no viewport.
  - Limpar `Data de saída` e salvar hoje **não** persiste: o front envia `departureDate: null` e a API trata como campo omitido, mantendo a data (só limpa ao reabrir um `ENTREGUE`/`DESCARTADO`). Item aberto no backlog; não registre como falha do front.
- **Cliente com `gender` legado (`MALE`/`FEMALE`):**
  - Abrir o cliente do `seed_reference.sql` (`gender = 'MALE'`): o dropdown exibe `"Masculino"` sem assertion.
- **Contato "Realizado":** `has_made_contact=t`. A edição abre com duplo clique no card (use o JS acima) e deve vir preenchida.
- **Toast acima de modal:** provocar erro com diálogo de contato ou pagamento aberto e confirmar que o toast do `SnackBarUtil` fica visível sobre o diálogo.
- **Rascunho da edição do aparelho:**
  - Urgência e status salvam na hora (PUT), mas o texto digitado não pode sumir.
  - Com a API parada, Salvar deve mostrar erro e manter a edição.
  - Com a API de volta, deve salvar e sair da edição.
- **Auth:**
  - Um 403 sem código de credencial não desloga.
  - Um 400 do gateway no refresh também não; o log deve trazer "Transient refresh failure (400). Keeping session".
  - O 403 de papel (`auth.access.denied`) exige uma key não-ADMIN: insira outra em `api_keys` manualmente.

## 5. Limpar
```bash
bash $SKILL/scripts/down.sh $STATE
```
- Pare também o `flutter run` e a sessão do navegador (`preview_list` → `preview_stop`, se aplicável).
- O script remove containers, rede, imagem `e2e-local-api:local`, segredos e envs. Mantém `proxy.log` como evidência.
- A imagem do Postgres fica, porque pode ser compartilhada.
