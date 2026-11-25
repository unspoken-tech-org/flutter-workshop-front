#!/usr/bin/env bash
# Sourced by run_desktop_headless.sh and run_integration_tests.sh.
# start_headless_kwin <width>x<height> <state-dir>
#   Starts a headless KWin on socket wayland-agent-<WxH> unless it is already
#   up (one per window size, left running for reuse) and sets SOCKET. The
#   output leaves room for the title bar.
start_headless_kwin() {
  local window=$1 state=$2 w h runtime
  case "$window" in
    [0-9]*x[0-9]*) w=${window%x*}; h=${window#*x} ;;
    *) echo "WINDOW must be <width>x<height>"; return 1 ;;
  esac
  SOCKET=wayland-agent-$window
  runtime=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
  [ -S "$runtime/$SOCKET" ] && return 0
  env -u WAYLAND_DISPLAY -u DISPLAY kwin_wayland --virtual --socket "$SOCKET" \
    --width "$w" --height $((h + 100)) > "$state/kwin.log" 2>&1 &
  echo $! > "$state/kwin.pid"
  timeout 20 bash -c "until [ -S \"$runtime/$SOCKET\" ]; do sleep 0.5; done" \
    || { echo "headless KWin did not start; see $state/kwin.log"; return 1; }
}
