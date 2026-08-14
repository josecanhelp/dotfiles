{ lib, ... }:

{
  # /bin/zsh is Apple's own zsh, present on every Mac without Nix installing
  # anything. Platform-specific because it does not exist on Linux, and tmux
  # given a nonexistent shell refuses to start rather than falling back.
  programs.tmux.shell = "/bin/zsh";

  # This block stays together so the generated tmux.conf keeps its existing
  # order. It supports the osascript notification and clears the Claude marker
  # set by ~/.claude/notify.sh.
  programs.tmux.extraConfig = lib.mkAfter ''
    # Fire macOS notification when any pane rings the bell (e.g. Claude Code)
    set -g bell-action any
    set -g visual-bell off
    set-hook -g alert-bell 'run-shell "osascript -e \"display notification \\\"Claude requires your attention\\\" with title \\\"Claude Code\\\"\""'

    # Clear the Claude attention marker (@claude_alert) the moment its window is
    # focused. The marker itself is set by ~/.claude/notify.sh (Claude Code hooks).
    set-hook -g session-window-changed 'set-option -w @claude_alert ""'
  '';
}
