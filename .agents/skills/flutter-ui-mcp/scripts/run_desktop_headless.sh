#!/usr/bin/env bash
# run_desktop_headless.sh <state-dir>
#   Starts a headless KWin (socket wayland-agent) if needed and runs the app on
#   Linux desktop inside it, with mcp_toolkit on. Writes:
#     <state-dir>/vm.txt       VM service URI (appears once the app is up)
#     <state-dir>/run.log      flutter run output
#     <state-dir>/kwin.pid     headless KWin pid (left running for reuse)
#     <state-dir>/flutter.pid  flutter run pid
#   Runs until the app exits; start it in the background.
# Env: FLUTTER (default fvm 3.47.9, else flutter on PATH), DEFINES (default --dart-define-from-file=.env-local),
#      APP_DIR (default current dir), VM_PORT (fixed VM service port without
#      auth code, for the MCP server; default random port with auth code).
set -u
STATE=${1:?usage: run_desktop_headless.sh <state-dir>}
FLUTTER=${FLUTTER:-$HOME/fvm/versions/3.47.9/bin/flutter}
[ -x "$FLUTTER" ] || FLUTTER=flutter
DEFINES=${DEFINES:---dart-define-from-file=.env-local}
APP_DIR=${APP_DIR:-$PWD}
VM_FLAGS=""
[ -n "${VM_PORT:-}" ] && VM_FLAGS="--vm-service-port=$VM_PORT --disable-service-auth-codes"
SOCKET=wayland-agent
mkdir -p "$STATE"
rm -f "$STATE/vm.txt"

if [ ! -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/$SOCKET" ]; then
  env -u WAYLAND_DISPLAY -u DISPLAY kwin_wayland --virtual --socket "$SOCKET" \
    --width 1280 --height 800 > "$STATE/kwin.log" 2>&1 &
  echo $! > "$STATE/kwin.pid"
  timeout 20 bash -c "until [ -S \"\${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/$SOCKET\" ]; do sleep 0.5; done" \
    || { echo "headless KWin did not start; see $STATE/kwin.log"; exit 1; }
fi

cd "$APP_DIR" || exit 1
# shellcheck disable=SC2086
env -u DISPLAY WAYLAND_DISPLAY=$SOCKET GDK_BACKEND=wayland \
  "$FLUTTER" run -d linux $DEFINES --dart-define=MCP_TOOLKIT=true $VM_FLAGS \
  --vmservice-out-file="$STATE/vm.txt" < /dev/null > "$STATE/run.log" 2>&1 &
echo $! > "$STATE/flutter.pid"
wait "$(cat "$STATE/flutter.pid")"
