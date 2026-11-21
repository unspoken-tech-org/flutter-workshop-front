#!/usr/bin/env bash
# Remove só o que up.sh criou. NÃO roda `docker builder prune` (apaga o cache
# de build de toda a máquina).
# Uso: down.sh <state_dir> [--keep-images]
set -uo pipefail
STATE=${1:?state_dir}
# shellcheck disable=SC1091
[ -f "$STATE/state.env" ] && . "$STATE/state.env"
PREFIX=${PREFIX:-e2e-local}

[ -f "$STATE/proxy.pid" ] && kill "$(cat "$STATE/proxy.pid")" 2>/dev/null
docker rm -f "$PREFIX-api" "$PREFIX-db" >/dev/null 2>&1
docker network rm "$PREFIX-net" >/dev/null 2>&1
if [ "${2:-}" != "--keep-images" ]; then
  docker rmi "$PREFIX-api:local" >/dev/null 2>&1
fi
rm -rf "$STATE/secrets" "$STATE/api-src" "$STATE/test.env" "$STATE/test-auth.env" \
  "$STATE/proxy.pid" "$STATE/proxy.port" "$STATE/state.env"
echo "[e2e] removido: containers/rede $PREFIX-*, imagem $PREFIX-api:local, segredos e envs"
echo "[e2e] mantidos como evidência: $STATE/proxy.log $STATE/proxy.out"
echo "[e2e] a imagem do Postgres não é removida (pode ser compartilhada); remova à mão só se foi baixada para isto"
