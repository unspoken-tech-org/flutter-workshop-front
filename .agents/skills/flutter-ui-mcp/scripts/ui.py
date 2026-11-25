"""Short-output driver for the running app (flutter-mcp-toolkit CLI).

Usage: python3 -I ui.py --vm <vm-uri-file> <command> [args]

Targets: `id=<identifier>`, `label=<text>`, or bare text (an exact
identifier first, then an exact label or label line, then a unique label
substring). Among several matches, nodes inside the viewport win.

Commands (print `ok`, or `error: <code>: <detail>` and exit 1):
  snap [--id PREFIX] [--under TARGET]   compact tree: no empty nodes, no bounds
  tap TARGET                            scrolls the target into view first
  type TARGET TEXT                      types into the target's text field
  type-secret TARGET VAR FILE           types VAR's value from an env FILE;
                                        never prints the value
  wait TARGET [--gone] [--timeout MS]   identifier -> node predicate; text ->
                                        text/noText predicate
  assert-text TEXT / assert-no-text TEXT
  errors [COUNT]                        app errors, first line of each
  back                                  navigate pop
  key KEY                               press_key (e.g. Escape, Enter)
Env: FMTK_BIN (flutter-mcp-toolkit bin folder).
"""
import json
import os
import subprocess
import sys

FIELDS = ["ref", "type", "identifier", "label", "value", "hint", "enabled",
          "actions", "children", "visibleInViewport", "center"]
MAX_SCROLLS = 6


class UiError(Exception):
    def __init__(self, code, detail=""):
        super().__init__(code)
        self.code, self.detail = code, detail


def cli_path():
    base = os.environ.get("FMTK_BIN") or os.path.expanduser(
        "~/.local/share/flutter-mcp-toolkit/bin")
    path = os.path.join(base, "flutter-mcp-toolkit")
    if not os.access(path, os.X_OK):
        raise UiError("fmtk_missing", f"{path}; set FMTK_BIN")
    return path


class App:
    def __init__(self, vm_file):
        with open(vm_file) as f:
            self.uri = f.read().strip()
        self.cli = cli_path()

    def call(self, name, args=None, secret=False):
        proc = subprocess.run(
            [self.cli, "--vm-service-uri", self.uri, "exec", "--name", name,
             "--args", json.dumps(args or {})],
            capture_output=True, text=True, check=False)
        try:
            envelope = json.loads(proc.stdout)
        except ValueError:
            detail = "" if secret else (proc.stdout + proc.stderr).strip()[:300]
            raise UiError("cli_failed", detail) from None
        if not envelope.get("ok"):
            err = envelope.get("error") or {}
            code = err.get("code", "failed") if isinstance(err, dict) else "failed"
            msg = "" if secret else (
                err.get("message", "") if isinstance(err, dict) else str(err))
            raise UiError(code, msg[:300])
        return envelope.get("data") or {}

    def snapshot(self, **extra):
        return Snapshot(self.call("semantic_snapshot", {"fields": FIELDS, **extra}))


class Snapshot:
    def __init__(self, data):
        self.id = data.get("snapshot_id")
        self.viewport = data.get("viewport") or {}
        self.nodes = data.get("nodes") or []
        self.by_ref = {n["ref"]: n for n in self.nodes}
        self.parent = {}
        for n in self.nodes:
            for child in n.get("children") or []:
                self.parent[child] = n["ref"]

    def descendants(self, node):
        out, stack = [], list(node.get("children") or [])
        while stack:
            child = self.by_ref.get(stack.pop(0))
            if child:
                out.append(child)
                stack[0:0] = child.get("children") or []
        return out

    def ancestors(self, node):
        ref = self.parent.get(node["ref"])
        while ref:
            yield self.by_ref[ref]
            ref = self.parent.get(ref)

    def find(self, target):
        kind, _, text = target.partition("=")
        if kind not in ("id", "label") or not text:
            kind, text = "any", target
        found = []
        if kind in ("id", "any"):
            found = [n for n in self.nodes if n.get("identifier") == text]
        if not found and kind in ("label", "any"):
            labels = [(n, n.get("label") or "") for n in self.nodes]
            found = [n for n, lab in labels if lab == text] or \
                [n for n, lab in labels if text in lab.split("\n")] or \
                [n for n, lab in labels if text in lab]
        visible = [n for n in found if n.get("visibleInViewport")]
        return visible or found

    def one(self, target):
        found = self.find(target)
        if not found:
            raise UiError("not_found", target)
        if len(found) > 1:
            refs = " ".join(n["ref"] for n in found[:6])
            raise UiError("ambiguous", f"{target} -> {refs}; use id=")
        return found[0]


def actionable(snap, node, want):
    """The node itself or its first descendant that can take the action."""
    def ok(n):
        if want == "text":
            return n.get("type") == "textField"
        return "tap" in (n.get("actions") or [])
    if want == "tap" and node.get("type") == "textField":
        # Never descend into a field's suffix buttons (clear, calendar).
        return node
    for n in [node, *snap.descendants(node)]:
        if ok(n):
            return n
    if want == "tap":
        # A label inside a card: the card is the tappable ancestor.
        parent = next((a for a in snap.ancestors(node) if ok(a)), None)
        if parent is not None and parent.get("type") != "scrollable":
            return parent
        # Read-only fields (date pickers) expose no tap action; tap_widget
        # still taps the node's centre.
        return node
    raise UiError("no_" + want + "_target", node["ref"])


def in_view(snap, node):
    vp, c = snap.viewport, node.get("center")
    if not c or not vp:
        return bool(node.get("visibleInViewport"))
    margin = 8
    return (vp["left"] + margin <= c["x"] <= vp["right"] - margin and
            vp["top"] + margin <= c["y"] <= vp["bottom"] - margin)


def reveal(app, target, want):
    """Snapshot, resolve, scroll into view; returns (snapshot, node)."""
    snap = app.snapshot()
    if not snap.find(target):
        kind, _, text = target.partition("=")
        by = "identifier" if kind == "id" else "text"
        query = text if kind in ("id", "label") else target
        try:
            app.call("reveal_search", {"query": query, "matchBy": by,
                                       "maxAttempts": 5})
        except UiError:
            pass
        snap = app.snapshot()
    for _ in range(MAX_SCROLLS):
        node = actionable(snap, snap.one(target), want)
        if in_view(snap, node):
            return snap, node
        scroll_into_view(app, snap, node)
        snap = app.snapshot()
    raise UiError("target_outside_viewport", target)


def scroll_into_view(app, snap, node):
    scrollable = next((a for a in snap.ancestors(node)
                       if a.get("type") == "scrollable"), None)
    if scrollable is None:
        raise UiError("target_outside_viewport", f"{node['ref']} has no scrollable ancestor")
    vp, c = snap.viewport, node["center"]
    dy = c["y"] - (vp["top"] + vp["bottom"]) / 2
    dx = c["x"] - (vp["left"] + vp["right"]) / 2
    if abs(dy) >= abs(dx):
        direction, dist = ("down" if dy > 0 else "up"), abs(dy)
    else:
        direction, dist = ("right" if dx > 0 else "left"), abs(dx)
    app.call("scroll", {"ref": scrollable["ref"], "direction": direction,
                        "distance": int(max(dist, 50)), "snapshotId": snap.id})


def describe(snap, node):
    parts = [node["ref"], node.get("type") or "?"]
    if node.get("identifier"):
        parts.append("#" + node["identifier"])
    label = (node.get("label") or "").replace("\n", " / ")
    if label:
        parts.append(json.dumps(label[:80], ensure_ascii=False))
    if node.get("value"):
        parts.append("=" + json.dumps(str(node["value"])[:60], ensure_ascii=False))
    if node.get("hint"):
        parts.append("hint=" + json.dumps(node["hint"][:40], ensure_ascii=False))
    if node.get("enabled") is False:
        parts.append("disabled")
    if not node.get("visibleInViewport", True):
        parts.append("offscreen")
    if not (label or node.get("identifier")) and node.get("children"):
        parts.append("> " + ",".join(node["children"][:4]))
    return " ".join(parts)


def is_noise(node):
    if node.get("identifier") or node.get("label") or node.get("value"):
        return False
    if node.get("type") in ("textField", "button", "checkbox", "switch", "radio"):
        return False
    return not (node.get("actions") and node.get("children"))


def cmd_snap(app, args):
    extra = {}
    while args:
        flag = args.pop(0)
        if flag == "--id":
            extra["identifierPrefix"] = args.pop(0)
        elif flag == "--under":
            extra["subtreeOf"] = args.pop(0)
        else:
            raise UiError("bad_args", flag)
    snap = app.snapshot(**extra)
    print("snapshot", snap.id)
    for n in snap.nodes:
        if not is_noise(n):
            print(describe(snap, n))


def env_value(path, var):
    with open(path) as f:
        for line in f:
            key, sep, value = line.rstrip("\n").partition("=")
            if sep and key.strip() == var:
                return value.strip()
    raise UiError("var_not_found", f"{var} in {path}")


def has_text(snap, text):
    return any(text in (n.get(k) or "") for n in snap.nodes
               for k in ("label", "value", "hint"))


def main(argv):
    if len(argv) < 3 or argv[0] != "--vm":
        print(__doc__)
        return 2
    app = App(argv[1])
    cmd, args = argv[2], argv[3:]
    if cmd == "snap":
        cmd_snap(app, args)
        return 0
    if cmd == "tap":
        snap, node = reveal(app, args[0], "tap")
        app.call("tap_widget", {"ref": node["ref"], "snapshotId": snap.id})
    elif cmd == "type":
        snap, node = reveal(app, args[0], "text")
        app.call("enter_text", {"ref": node["ref"], "text": args[1],
                                "snapshotId": snap.id})
    elif cmd == "type-secret":
        target, var, path = args
        value = env_value(path, var)
        snap, node = reveal(app, target, "text")
        app.call("enter_text", {"ref": node["ref"], "text": value,
                                "snapshotId": snap.id}, secret=True)
    elif cmd == "wait":
        target, gone, timeout = args[0], "--gone" in args, 10000
        if "--timeout" in args:
            timeout = int(args[args.index("--timeout") + 1])
        kind, _, text = target.partition("=")
        if kind == "id":
            pred = {"kind": "node", "identifier": text, "absent": gone}
        else:
            text = text if kind == "label" else target
            pred = {"kind": "noText" if gone else "text", "text": text}
        app.call("wait_for", {"predicate": pred, "timeoutMs": timeout})
    elif cmd in ("assert-text", "assert-no-text"):
        present = has_text(app.snapshot(), args[0])
        if present != (cmd == "assert-text"):
            raise UiError("assert_failed", ("missing: " if not present else "present: ") + args[0])
    elif cmd == "errors":
        count = int(args[0]) if args else 4
        errors = app.call("get_app_errors", {"count": count}).get("errors") or []
        print(f"errors {len(errors)}")
        for e in errors:
            msg = e.get("message", "") if isinstance(e, dict) else str(e)
            lines = [ln.strip() for ln in msg.splitlines() if ln.strip()]
            where = next((ln for ln in lines if "relevant error-causing widget" in ln), "")
            idx = lines.index(where) if where else -1
            loc = lines[idx + 1] if 0 <= idx < len(lines) - 1 else ""
            print("-", " ".join(lines[:2])[:200], ("@ " + loc[:120]) if loc else "")
        return 0
    elif cmd == "back":
        app.call("navigate", {"action": "pop"})
    elif cmd == "key":
        app.call("press_key", {"key": args[0]})
    else:
        print(__doc__)
        return 2
    print("ok")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except UiError as e:
        print(f"error: {e.code}: {e.detail}" if e.detail else f"error: {e.code}")
        sys.exit(1)
    except (IndexError, ValueError) as e:
        print(f"error: bad_args: {e}")
        sys.exit(2)
