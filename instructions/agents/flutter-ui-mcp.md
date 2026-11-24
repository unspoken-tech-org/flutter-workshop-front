# flutter-ui MCP: install

Only when the `mcp__flutter-ui__fmt_*` tools or `~/.local/share/flutter-mcp-toolkit/bin` are missing.

```bash
curl -fsSL https://raw.githubusercontent.com/Arenukvern/mcp_flutter/v8.0.0/install.sh -o /tmp/fmtk-install.sh
bash /tmp/fmtk-install.sh --version 8.0.0 --install-dir ~/.local/share/flutter-mcp-toolkit/bin
claude mcp add flutter-ui -s local -- ~/.local/share/flutter-mcp-toolkit/bin/flutter-mcp-toolkit-server \
  --dart-vm-host=localhost --dart-vm-port=8181 --save-images --idle-exit-minutes=60
```
- Keep the version equal to `mcp_toolkit` in `pubspec.yaml`. Binaries: Linux x64 and macOS arm64 only.
- The tools appear in a new session. A server in a project `.mcp.json` needs the user's approval in `claude` first.
- `VM_PORT` disables the VM service auth code: development machines only.
