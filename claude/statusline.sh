#!/usr/bin/env bash
# Claude Code status line. Does two jobs from the single invocation Claude Code
# gives us:
#
#   1. Publishes this session's live numbers into a PER-PANE tmux user option,
#      @claude_status, which tmux/tmuxline draws in status-right. Per-pane and
#      not global: several Claude sessions run at once, and a global option
#      would show whichever pane wrote last rather than the focused one.
#   2. Prints the keyboard hints back to Claude Code. Configuring any status
#      line suppresses the built-in footer hints, so this row puts them back.
#      They are static. The JSON payload carries no turn-running flag and the
#      script is not run at turn start, so "esc interrupt" cannot be made to
#      appear only while a turn is live the way the native hint does.
#
# Linked from ~/.claude/statusline.sh (nix/home/darwin/default.nix), so edits
# here take effect on the next status refresh with no rebuild. It is registered
# in ~/.claude/settings.json, which is deliberately unmanaged: the rest of
# ~/.claude is session state that must not be linked into the store.
#
# Claude Code captures stdout rather than attaching it to the terminal, so
# nothing here may read the terminal size directly. COLUMNS and LINES are
# exported for us if width ever matters.

set -uo pipefail

HINTS=$'\033[2mesc interrupt · ? shortcuts · hold space to speak\033[0m'

payload=$(cat)

# One jq pass, tab separated, always six fields so an empty value cannot shift
# the read. -1 stands in for an absent rate limit, which is how a payload from
# an account with no plan limits arrives.
IFS=$'\t' read -r model ctx cost five_hour seven_day ctx_state <<TSV
$(printf '%s' "$payload" | jq -r '
  (.context_window.used_percentage // 0) as $ctx
  | [ (.model.display_name // "claude")
    , ($ctx | floor)
    , (.cost.total_cost_usd // 0)
    , (.rate_limits.five_hour.used_percentage // -1 | floor)
    , (.rate_limits.seven_day.used_percentage // -1 | floor)
    , (if $ctx >= 90 then "hot" elif $ctx >= 70 then "warn" else "ok" end)
    ] | @tsv' 2>/dev/null)
TSV

# A payload this script cannot read is not worth a broken status bar. Print the
# hints and leave whatever the bar already shows in place.
if [ -z "${model:-}" ]; then
  printf '%s\n' "$HINTS"
  exit 0
fi

segment=$(printf '%s · %s%% · $%.2f' "$model" "$ctx" "${cost:-0}")
[ "${five_hour:-0}" -ge 0 ] 2>/dev/null && segment="$segment · 5h ${five_hour}%"
[ "${seven_day:-0}" -ge 0 ] 2>/dev/null && segment="$segment · 7d ${seven_day}%"

if [ -n "${TMUX_PANE:-}" ] && command -v tmux >/dev/null 2>&1; then
  # Failures are swallowed on purpose: a pane that has gone away, or a tmux
  # server that has, must never take the status line down with it.
  tmux set -p -t "$TMUX_PANE" @claude_status "$segment" 2>/dev/null || true
  tmux set -p -t "$TMUX_PANE" @claude_ctx_state "${ctx_state:-ok}" 2>/dev/null || true
  tmux set -p -t "$TMUX_PANE" @claude_status_at "$(date +%s)" 2>/dev/null || true
else
  # Outside tmux there is no bar to publish to, so the numbers go in the row
  # that would otherwise carry only the hints.
  printf '\033[2m%s\033[0m\n' "$segment"
fi

printf '%s\n' "$HINTS"
