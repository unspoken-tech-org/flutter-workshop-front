#!/usr/bin/env bash
# run_integration_tests.sh <e2e-state-dir> [test-file...]
#   Runs integration_test/ (or the given files) on Linux desktop inside a
#   headless KWin, against the local E2E API started by the e2e-local-api
#   skill (up.sh), and prints only one PASS/FAIL line per test plus a summary.
#   Uses <e2e-state-dir>/test-auth.env (never printed) and the proxy log
#   <e2e-state-dir>/proxy.log. Full output: <e2e-state-dir>/itest.log.
#   Exit status: 0 all passed, 1 a test failed, 2 nothing ran (build error).
# Env: FLUTTER (default fvm 3.47.9, else flutter on PATH), APP_DIR (default
#      current dir), WINDOW (app window <width>x<height>, default 1280x1000),
#      HEADED (1 = run on the user's own Wayland session instead of a
#      headless KWin).
#   Storage uses its own namespace ("itest") and is reset at every boot.
set -u
E2E=${1:?usage: run_integration_tests.sh <e2e-state-dir> [test-file...]}
shift
FLUTTER=${FLUTTER:-$HOME/fvm/versions/3.47.9/bin/flutter}
[ -x "$FLUTTER" ] || FLUTTER=flutter
APP_DIR=${APP_DIR:-$PWD}
WINDOW=${WINDOW:-1280x1000}
HERE=$(cd "$(dirname "$0")" && pwd)
E2E=$(cd "$E2E" && pwd)
[ -s "$E2E/test-auth.env" ] || { echo "missing $E2E/test-auth.env (run e2e-local-api up.sh)"; exit 2; }
# One `flutter test` per file: on Linux desktop a second file in the same run
# fails with "Unable to start the app on the device".
[ $# -eq 0 ] && set -- integration_test/*_test.dart

# shellcheck source=headless_kwin.sh
. "$HERE/headless_kwin.sh"
if [ "${HEADED:-0}" = 1 ]; then SOCKET=${WAYLAND_DISPLAY:?HEADED needs WAYLAND_DISPLAY}; else start_headless_kwin "$WINDOW" "$E2E" || exit 2; fi

cd "$APP_DIR" || exit 2
: > "$E2E/itest.log"
rm -f "$E2E"/itest-*.json
n=0
for file in "$@"; do
  n=$((n + 1))
  env -u DISPLAY WAYLAND_DISPLAY="$SOCKET" GDK_BACKEND=wayland \
    WORKSHOP_WINDOW_SIZE="$WINDOW" E2E_PROXY_LOG="$E2E/proxy.log" \
    "$FLUTTER" test "$file" -d linux --machine \
    --dart-define-from-file="$E2E/test-auth.env" \
    --dart-define=STORAGE_NAMESPACE=itest --dart-define=RESET_STORAGE=true \
    < /dev/null > "$E2E/itest-$n.json" 2>> "$E2E/itest.log"
done

python3 -I - "$E2E/itest.log" "$E2E"/itest-*.json <<'PY'
import json, sys

# Test ids restart in every `flutter test` run: key them by (run, id).
names, errors, thrown, results, pending = {}, {}, {}, [], set()
log = open(sys.argv[1], "a")
for run, path in enumerate(sys.argv[2:]):
    with open(path, errors="replace") as f:
        lines = f.readlines()
    for line in lines:
        try:
            event = json.loads(line)
        except ValueError:
            log.write(line)
            continue
        if not isinstance(event, dict):
            continue
        kind = event.get("type")
        key = (run, event.get("testID"))
        if kind == "testStart":
            test = event["test"]
            names[(run, test["id"])] = test["name"]
        elif kind == "error":
            errors.setdefault(key, event.get("error", ""))
            log.write(f"[{names.get(key)}] {event.get('error')}\n"
                      f"{event.get('stackTrace', '')}\n")
        elif kind == "print":
            message = event.get("message", "")
            log.write(message + "\n")
            # The framework prints "The following X was thrown ..." and the
            # exception message as separate lines.
            if key in pending and message.strip():
                thrown.setdefault(key, message.strip())
                pending.discard(key)
            elif "was thrown" in message and key not in thrown:
                pending.add(key)
        elif kind == "testDone" and not event.get("hidden"):
            results.append((key, event.get("result")))

failed = 0
for key, result in results:
    name = names.get(key, str(key))
    if result == "success":
        print("PASS", name)
    else:
        failed += 1
        reason = (thrown.get(key) or errors.get(key) or result
                  or "").strip().splitlines()
        print("FAIL", name, "--", reason[0][:160] if reason else "")
if not results:
    print(f"no test ran; see {sys.argv[1]}")
    sys.exit(2)
print(f"{len(results) - failed} passed, {failed} failed")
sys.exit(1 if failed else 0)
PY
