#!/usr/bin/env bash
# Sobe API + Postgres sintético isolados (prefixo e2e-local-) e o proxy de falhas.
# Uso: up.sh <repo_da_api> <state_dir>
# Gera em <state_dir>: test.env (sem chave), test-auth.env (com DEV_API_KEY),
# proxy.log, state.env. Nunca imprime segredos.
set -euo pipefail

API_REPO=${1:?repo da API}
STATE=${2:?diretório de estado (use o scratchpad)}
HERE=$(cd "$(dirname "$0")" && pwd)
PREFIX=${E2E_PREFIX:-e2e-local}
PG_IMAGE=${E2E_PG_IMAGE:-postgres:16.15-alpine3.24}

mkdir -p "$STATE/secrets" "$STATE/api-src"
umask 077
[ -s "$STATE/secrets/dbpass" ] || python3 -c "import secrets;print(secrets.token_urlsafe(24),end='')" >"$STATE/secrets/dbpass"
[ -s "$STATE/secrets/apikey" ] || python3 -c "import secrets;print('e2e-'+secrets.token_hex(24),end='')" >"$STATE/secrets/apikey"
# Os containers rodam com outro uid: os arquivos precisam ser legíveis.
chmod 755 "$STATE/secrets"; chmod 644 "$STATE/secrets/dbpass" "$STATE/secrets/apikey"
umask 022

API_HEAD=$(git -C "$API_REPO" rev-parse HEAD)
EXISTING_HEAD=$(docker image inspect --format '{{index .Config.Labels "e2e.api.head"}}' "$PREFIX-api:local" 2>/dev/null || true)

echo "[e2e] copiando HEAD da API (git archive, sem tocar o checkout)"
git -C "$API_REPO" archive HEAD | tar -x -C "$STATE/api-src"

if [ "${E2E_REBUILD:-0}" != "1" ] && [ "$EXISTING_HEAD" = "$API_HEAD" ]; then
  echo "[e2e] reutilizando imagem $PREFIX-api:local (HEAD ${API_HEAD:0:7}; use E2E_REBUILD=1 para rebuild)"
else
  echo "[e2e] build da imagem $PREFIX-api:local (alguns minutos na 1a vez)"
  docker build -q --label "e2e.api.head=$API_HEAD" -t "$PREFIX-api:local" -f "$STATE/api-src/apps/api/docker/Dockerfile" "$STATE/api-src" >/dev/null
fi

docker network inspect "$PREFIX-net" >/dev/null 2>&1 || docker network create "$PREFIX-net" >/dev/null

echo "[e2e] Postgres sintético (tmpfs)"
# Não usar --user: o initdb falha ao ajustar permissões do tmpfs.
docker run -d --name "$PREFIX-db" --network "$PREFIX-net" \
  -e POSTGRES_DB=workshop_synthetic -e POSTGRES_USER=workshop_synthetic \
  -e POSTGRES_PASSWORD_FILE=/run/secrets/dbpass -e TZ=America/Sao_Paulo \
  -v "$STATE/secrets/dbpass:/run/secrets/dbpass:ro" \
  --tmpfs /var/lib/postgresql/data:size=256m \
  "$PG_IMAGE" postgres -c timezone=America/Sao_Paulo >/dev/null
timeout 90 bash -c "until docker exec $PREFIX-db pg_isready -U workshop_synthetic -d workshop_synthetic >/dev/null 2>&1; do sleep 2; done"

echo "[e2e] API (perfil qa)"
docker run -d --name "$PREFIX-api" --network "$PREFIX-net" -p 127.0.0.1::8080 \
  -e SPRING_PROFILES_ACTIVE=qa \
  -e SPRING_DATASOURCE_URL="jdbc:postgresql://$PREFIX-db:5432/workshop_synthetic" \
  -e SPRING_DATASOURCE_USERNAME=workshop_synthetic \
  -e SPRING_CONFIG_IMPORT=configtree:/run/secrets/ \
  -e TZ=America/Sao_Paulo -e JAVA_TOOL_OPTIONS="-Xmx768m -Duser.timezone=America/Sao_Paulo" \
  -v "$STATE/secrets/dbpass:/run/secrets/SPRING_DATASOURCE_PASSWORD:ro" \
  -v "$STATE/api-src/apps/api/src/main/resources/keys:/app/config/qa_keys:ro" \
  "$PREFIX-api:local" >/dev/null
timeout 180 bash -c "until docker logs $PREFIX-api 2>&1 | grep -qE 'Started WorkshopApplication|Application run failed'; do sleep 3; done"
if docker logs "$PREFIX-api" 2>&1 | grep -q 'Application run failed'; then
  echo "[e2e] API falhou ao subir; veja: docker logs $PREFIX-api" >&2; exit 1
fi
API_PORT=$(docker port "$PREFIX-api" 8080/tcp | head -1 | sed 's/.*://')

echo "[e2e] seed: API key (seed.sql do projeto) + dados de referência"
docker run --rm --network "$PREFIX-net" \
  -v "$STATE/secrets/dbpass:/run/secrets/dbpass:ro" \
  -v "$STATE/secrets/apikey:/run/secrets/synthetic_api_key:ro" \
  -v "$STATE/api-src/platform/observability/local/synthetic:/seed:ro" \
  -v "$HERE/seed_reference.sql:/ref/seed_reference.sql:ro" \
  --entrypoint sh "$PG_IMAGE" -c \
  'export PGPASSWORD="$(cat /run/secrets/dbpass)"; psql -h '"$PREFIX"'-db -U workshop_synthetic -d workshop_synthetic -q -f /seed/seed.sql && psql -h '"$PREFIX"'-db -U workshop_synthetic -d workshop_synthetic -q -f /ref/seed_reference.sql'

echo "[e2e] proxy de falhas"
PROXY_PORT=$(python3 -c "import socket;s=socket.socket();s.bind(('127.0.0.1',0));print(s.getsockname()[1])")
: >"$STATE/proxy.log"
nohup python3 -I "$HERE/e2e_proxy.py" "http://127.0.0.1:$API_PORT" "$STATE/proxy.port" "$STATE/proxy.log" "$PROXY_PORT" \
  >"$STATE/proxy.out" 2>&1 &
echo $! >"$STATE/proxy.pid"
timeout 30 bash -c "until curl -sf http://127.0.0.1:$PROXY_PORT/actuator/health >/dev/null; do sleep 1; done"

umask 077
printf 'ENV=local\nBASE_URL=http://127.0.0.1:%s\nGITHUB_OWNER=example\nGITHUB_REPO=example\n' "$PROXY_PORT" >"$STATE/test.env"
{ cat "$STATE/test.env"; printf 'DEV_API_KEY=%s\n' "$(cat "$STATE/secrets/apikey")"; } >"$STATE/test-auth.env"
printf 'PREFIX=%s\nAPI_PORT=%s\nPROXY_PORT=%s\nPG_IMAGE=%s\n' "$PREFIX" "$API_PORT" "$PROXY_PORT" "$PG_IMAGE" >"$STATE/state.env"

echo "[e2e] pronto: proxy http://127.0.0.1:$PROXY_PORT -> API :$API_PORT"
echo "[e2e] env sem chave: $STATE/test.env | com chave: $STATE/test-auth.env"
