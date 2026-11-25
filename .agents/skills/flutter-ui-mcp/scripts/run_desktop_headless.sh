#!/usr/bin/env bash
# run_desktop_headless.sh <state-dir>
#   Starts a headless KWin (socket wayland-agent-<WINDOW>) if needed and runs
#   the app on Linux desktop inside it, with mcp_toolkit on. Writes:
#     <state-dir>/vm.txt       VM service URI (appears once the app is up)
#     <state-dir>/run.log      flutter run output
#     <state-dir>/kwin.pid     headless KWin pid (left running for reuse)
#     <state-dir>/flutter.pid  flutter run pid
#   Runs until the app exits; start it in the background.
# Env: FLUTTER (default fvm 3.47.9, else flutter on PATH), DEFINES (default --dart-define-from-file=.env-local),
#      APP_DIR (default current dir), VM_PORT (fixed VM service port without
#      auth code, for the MCP server; default random port with auth code),
#      WINDOW (app window <width>x<height>, default 1280x1000),
#      STORAGE_NAMESPACE (secure-storage key prefix, default "agent": the run
#      never reads or overwrites the developer's own setup),
#      CLEAN_STORAGE (1 = drop the namespace's API key and tokens at boot, so a
#      key from another run is not reused; default 1; 0 keeps them).
set -u
STATE=${1:?usage: run_desktop_headless.sh <state-dir>}
FLUTTER=${FLUTTER:-$HOME/fvm/versions/3.47.9/bin/flutter}
[ -x "$FLUTTER" ] || FLUTTER=flutter
DEFINES=${DEFINES:---dart-define-from-file=.env-local}
APP_DIR=${APP_DIR:-$PWD}
WINDOW=${WINDOW:-1280x1000}
STORAGE_NAMESPACE=${STORAGE_NAMESPACE:-agent}
CLEAN_STORAGE=${CLEAN_STORAGE:-1}
VM_FLAGS=""
[ -n "${VM_PORT:-}" ] && VM_FLAGS="--vm-service-port=$VM_PORT --disable-service-auth-codes"
STORAGE_FLAGS="--dart-define=STORAGE_NAMESPACE=$STORAGE_NAMESPACE"
[ "$CLEAN_STORAGE" = 1 ] && STORAGE_FLAGS="$STORAGE_FLAGS --dart-define=RESET_STORAGE=true"
mkdir -p "$STATE"
rm -f "$STATE/vm.txt"
# shellcheck source=headless_kwin.sh
. "$(dirname "$0")/headless_kwin.sh"
start_headless_kwin "$WINDOW" "$STATE" || exit 1

cd "$APP_DIR" || exit 1
# shellcheck disable=SC2086
env -u DISPLAY WAYLAND_DISPLAY=$SOCKET GDK_BACKEND=wayland WORKSHOP_WINDOW_SIZE="$WINDOW" \
  "$FLUTTER" run -d linux $DEFINES --dart-define=MCP_TOOLKIT=true $STORAGE_FLAGS $VM_FLAGS \
  --vmservice-out-file="$STATE/vm.txt" < /dev/null > "$STATE/run.log" 2>&1 &
echo $! > "$STATE/flutter.pid"
wait "$(cat "$STATE/flutter.pid")"
