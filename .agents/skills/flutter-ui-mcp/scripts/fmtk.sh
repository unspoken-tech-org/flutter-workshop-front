#!/usr/bin/env bash
# fmtk.sh <vm-uri-file> <command> [argsJSON]
#   Runs `flutter-mcp-toolkit exec` against the app whose VM service URI is in <vm-uri-file>.
# fmtk.sh <vm-uri-file> snap
#   Compact semantic snapshot: one line per labeled node or text field
#   (ref, type, label, value, enabled).
# Needs FMTK_BIN pointing at the extracted flutter-mcp-toolkit bin/ folder.
set -u
VMFILE=${1:?usage: fmtk.sh <vm-uri-file> <command> [argsJSON]}
CMD=${2:?usage: fmtk.sh <vm-uri-file> <command> [argsJSON]}
ARGS=${3:-}
[ -z "$ARGS" ] && ARGS='{}'
CLI="${FMTK_BIN:?set FMTK_BIN to the flutter-mcp-toolkit bin folder}/flutter-mcp-toolkit"
URI=$(cat "$VMFILE")

if [ "$CMD" = "snap" ]; then
  "$CLI" --vm-service-uri "$URI" exec --name semantic_snapshot \
    --args '{"fields":["ref","type","label","value","enabled"]}' 2>&1 | python3 -c '
import json, sys
raw = sys.stdin.read()
try:
    d = json.loads(raw)
except ValueError:
    print(raw); sys.exit(1)
if not d.get("ok"):
    print(json.dumps(d.get("error"))); sys.exit(1)
data = d["data"]; print("snapshot", data["snapshot_id"])
for n in data["nodes"]:
    if n.get("label") or "text" in n.get("type", ""):
        print(n["ref"], n.get("type"), repr(n.get("label", "")), repr(n.get("value", "")), "enabled=%s" % n.get("enabled"))'
  exit $?
fi

"$CLI" --vm-service-uri "$URI" exec --name "$CMD" --args "$ARGS" 2>&1
