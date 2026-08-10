#!/bin/bash
# Claude Code hook: macOS notification + tmux window attention marker.
# Arg 1 is the state: "input" (Claude needs feedback/permission) or
# "done" (Claude finished a task). Defaults to "done".
state="${1:-done}"

osascript -e 'display notification "Claude requires your attention" with title "Claude Code"'

# Flag this pane's tmux window so its status entry shows an icon, but only
# when that window is NOT the one currently in view. This keeps the window
# you're actively working in from flagging itself on every turn.
if [ -n "$TMUX_PANE" ] && command -v tmux >/dev/null 2>&1; then
  active=$(tmux display-message -p -t "$TMUX_PANE" '#{window_active}' 2>/dev/null)
  if [ "$active" != "1" ]; then
    tmux set-option -w -t "$TMUX_PANE" @claude_alert "$state" 2>/dev/null
  fi
fi
