# flutter-ui MCP: setup and background

Setup for the `flutter-ui-mcp` skill (`.agents/skills/flutter-ui-mcp/`). The
skill covers using the tools; this file covers installing them and the
decisions behind them.

## App side
Already in the code: `lib/core/agent/agent_toolkit.dart` wraps `main` in the
`mcp_toolkit` bootstrap when the app runs with `--dart-define=MCP_TOOLKIT=true`,
never in release. The skill scripts pass that define. `mcp_toolkit` 8.x needs
Flutter 3.44+; the CI uses 3.47.9, and the scripts fall back to
`~/fvm/versions/3.47.9/bin/flutter` when it exists.

## Install the CLI and server
Binaries `flutter-mcp-toolkit` (CLI, alias `fmtk`) and
`flutter-mcp-toolkit-server` from
[Arenukvern/mcp_flutter](https://github.com/Arenukvern/mcp_flutter), pinned to
the `mcp_toolkit` version in `pubspec.yaml`:
```bash
curl -fsSL https://raw.githubusercontent.com/Arenukvern/mcp_flutter/v8.0.0/install.sh -o /tmp/fmtk-install.sh
bash /tmp/fmtk-install.sh --version 8.0.0 --install-dir ~/.local/share/flutter-mcp-toolkit/bin
```
- `fmtk.sh` looks there; set `FMTK_BIN` for another folder.
- The installer appends to `.bashrc`/`.zshrc` PATH (not fish); the skill does
  not need PATH.
- The sha256 is only checked against the release's own `checksums.txt`; there
  is no signature.
- Binaries exist only for Linux x64 and macOS arm64. The server is not on
  pub.dev or npm.

## Register the MCP server
```bash
claude mcp add flutter-ui -s local -- ~/.local/share/flutter-mcp-toolkit/bin/flutter-mcp-toolkit-server \
  --dart-vm-host=localhost --dart-vm-port=8181 --save-images --idle-exit-minutes=60
```
- `-s local` keeps it off the repo's `.mcp.json`, since the binary path differs
  per machine. A server in a project `.mcp.json` loads only after the user
  approves it in `claude` (`claude mcp list` shows *Pending approval*).
- Tools appear only in a new Claude Code session.
- The server connects by host and port, without the URI auth code, so the app
  runs with `VM_PORT=8181`, which adds `--vm-service-port=8181
  --disable-service-auth-codes`. That leaves the VM service open to any local
  process on 8181: development machines only.
- `--save-images` saves files only for `get_screenshots` and
  `capture_ui_snapshot`, into `.mcp_screenshots/` in the server's working
  directory.
- `fmtk doctor --json` reports `vm_target_reachable: fail` against a VM service
  without an auth code even when the app answers; use `discover_debug_apps`.

**Official plugin (not used):** `/plugin marketplace add Arenukvern/mcp_flutter`
then `/plugin install flutter-mcp-toolkit@flutter-mcp-toolkit`. It does not
install the binary, registers its own server (duplicate tools if the
`claude mcp add` above is also active) and ships 16 generic skills that
compete with ours. Use one or the other.

## Headless runs
- Linux desktop: `kwin_wayland --virtual --socket wayland-agent`, app run with
  `WAYLAND_DISPLAY=wayland-agent`.
- Web: `flutter run -d web-server` on port 3000 (the local API's CORS accepts
  only `localhost:3000`, `:8080`, `:8081`, unless you use the `e2e-local-api`
  proxy) plus a separate headless Chrome. `flutter run -d chrome` with
  `--headless=new` fails (*"Multiple targets are not supported in headless
  mode"*), and normal Chrome inside headless KWin never fires
  `requestAnimationFrame`.

## App-registered tools (none yet)
`mcp_toolkit` lets the app register its own tools and resources, reached via
`fmt_list_client_tools_and_resources`, `fmt_client_tool` and
`fmt_client_resource`. Today the list has only the toolkit's `app_identity` and
`select_widget_at_point`. A candidate: expose or change the current go_router
route, since `navigate push` does not work with go_router. If you add one:
- Register with `MCPToolkitBinding.instance.addEntries(entries: {AgentCallEntry.tool(...)})`
  in `agent_toolkit.dart`, before `bootstrapFlutter`, so it stays behind
  `MCP_TOOLKIT=true`.
- Use a `workshop_` `snake_case` name; a name that collides with a built-in
  tool is silently ignored.
- Never return keys, tokens or customer data (the `AppLogger` rules apply).
- In 8.0.0, re-registering a name after hot reload may keep the old handler:
  hot restart.
- Recipes: `plugin/skills/flutter-mcp-toolkit-custom-tools/SKILL.md` in the
  mcp_flutter repo.
