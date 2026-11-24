#!/usr/bin/env bash
# run_web_headless.sh <state-dir> [port]
#   Serves the app with `flutter run -d web-server` (mcp_toolkit on) and opens
#   it in a headless Chrome (CDP on 9333). Port defaults to 3000, the origin the
#   local API's CORS accepts. Writes:
#     <state-dir>/vm.txt       VM service URI (appears after Chrome connects)
#     <state-dir>/run.log      flutter run output
#     <state-dir>/flutter.pid  flutter run pid
#     <state-dir>/chrome.pid   headless Chrome pid
#   Runs until killed; start it in the background. Stops Chrome on exit.
# Env: FLUTTER (default fvm 3.47.9, else flutter on PATH), DEFINES (default --dart-define-from-file=.env-local),
#      APP_DIR (default current dir), VM_PORT (fixed VM service port without
#      auth code, for the MCP server; default random port with auth code), CHROME (default google-chrome-stable).
set -u
STATE=${1:?usage: run_web_headless.sh <state-dir> [port]}
PORT=${2:-3000}
FLUTTER=${FLUTTER:-$HOME/fvm/versions/3.47.9/bin/flutter}
[ -x "$FLUTTER" ] || FLUTTER=flutter
DEFINES=${DEFINES:---dart-define-from-file=.env-local}
APP_DIR=${APP_DIR:-$PWD}
VM_FLAGS=""
[ -n "${VM_PORT:-}" ] && VM_FLAGS="--vm-service-port=$VM_PORT --disable-service-auth-codes"
CHROME=${CHROME:-google-chrome-stable}
mkdir -p "$STATE"
rm -f "$STATE/vm.txt"

cd "$APP_DIR" || exit 1
# shellcheck disable=SC2086
"$FLUTTER" run -d web-server --web-port="$PORT" --web-hostname=localhost \
  $DEFINES --dart-define=MCP_TOOLKIT=true $VM_FLAGS \
  --vmservice-out-file="$STATE/vm.txt" < /dev/null > "$STATE/run.log" 2>&1 &
FP=$!; echo $FP > "$STATE/flutter.pid"

until grep -q 'is being served at' "$STATE/run.log" 2>/dev/null; do
  kill -0 $FP 2>/dev/null || { echo "flutter run exited; see $STATE/run.log"; exit 1; }
  sleep 1
done

PROFILE=$(mktemp -d "$STATE/chrome-profile.XXXX")
"$CHROME" --headless=new --user-data-dir="$PROFILE" --remote-debugging-port=9333 \
  --window-size=1280,800 --no-first-run "http://localhost:$PORT" > "$STATE/chrome.log" 2>&1 &
CP=$!; echo $CP > "$STATE/chrome.pid"
trap 'kill $CP $FP 2>/dev/null' EXIT TERM INT
wait $FP
