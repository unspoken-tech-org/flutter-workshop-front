#!/usr/bin/env bash
# Para (down) ou religa (up) a API, mantendo o proxy na mesma porta.
# Ao religar, a porta publicada da API muda: o proxy é reiniciado apontando para ela.
# Uso: api_restart.sh <state_dir> down|up
set -euo pipefail
STATE=${1:?state_dir}; ACTION=${2:?down|up}
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$STATE/state.env"

if [ "$ACTION" = down ]; then
  docker stop "$PREFIX-api" >/dev/null && echo "[e2e] API parada (proxy devolve 502)"
  exit 0
fi

docker start "$PREFIX-api" >/dev/null
API_PORT=$(docker port "$PREFIX-api" 8080/tcp | head -1 | sed 's/.*://')
PID=$(cat "$STATE/proxy.pid")
kill "$PID" 2>/dev/null || true
timeout 10 bash -c "while kill -0 $PID 2>/dev/null; do sleep 0.5; done" || true
nohup python3 -I "$HERE/e2e_proxy.py" "http://127.0.0.1:$API_PORT" "$STATE/proxy.port" "$STATE/proxy.log" "$PROXY_PORT" \
  >>"$STATE/proxy.out" 2>&1 &
echo $! >"$STATE/proxy.pid"
sed -i "s/^API_PORT=.*/API_PORT=$API_PORT/" "$STATE/state.env"
timeout 150 bash -c "until curl -sf http://127.0.0.1:$PROXY_PORT/actuator/health >/dev/null; do sleep 2; done"
echo "[e2e] API de volta em :$API_PORT via proxy :$PROXY_PORT"
