{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;

    # home-manager defaults this to true, which prepends tmux-sensible and
    # silently changes defaults this config never set: focus-events,
    # aggressive-resize, status-keys emacs, C-p/C-n window bindings, and
    # default-command wrapping every pane in reattach-to-user-namespace.
    # Off keeps this a pure conversion.
    sensibleOnTop = false;

    # Replaces three lines: set -g prefix C-a, unbind-key C-b,
    # bind-key C-a send-prefix.
    prefix = "C-a";

    keyMode = "vi";
    mouse = true;

    # Must be set: the option defaults to 2000, not 4096.
    historyLimit = 4096;

    # Written explicitly even though it matches the current module default,
    # because the value is deliberate and a future default change should not
    # silently alter it.
    escapeTime = 10;

    terminal = "tmux-256color";

    # Reproduces the existing `bind -r H/J/K/L resize-pane` lines exactly.
    # Also adds `prefix + h/j/k/l` for pane selection, which were unbound
    # before. Additive, and accepted deliberately.
    resizeAmount = 5;
    customPaneNavigationAndResize = true;

    # tpm is gone; Nix supplies these. tmux-fzf and vim-tmux-navigator are
    # deliberately absent: the former was never declared and never loaded,
    # the latter is hand-rolled in extraConfig below with a custom C-d
    # binding the plugin has no equivalent for.
    plugins = with pkgs.tmuxPlugins; [
      resurrect
      continuum
      copycat
      yank
    ];

    extraConfig = ''
      # Plugin configurations
      # Off deliberately. Continuum's own osx_enable.sh writes
      # ~/Library/LaunchAgents/Tmux.Start.plist pointing at whatever directory
      # the plugin happens to live in, which is why the old registration still
      # pointed into ~/.tmux/plugins long after tpm was retired, failing with
      # exit 1 at every login. The launchd.agents.tmux-boot block below
      # declares the same thing against a store path instead.
      #
      # Setting this off is also what makes continuum run osx_disable.sh and
      # delete its own stale plist, so it cleans up after itself.
      set -g @continuum-boot 'off'
      set -g @continuum-restore 'on'
      set -g @resurrect-capture-pane-contents 'on'

      set -ag terminal-features ",alacritty:RGB" # True color + italics in Alacritty
      set -g renumber-windows on
      set-option -g allow-rename off # Do not rename windows
      set -g allow-passthrough on
      set -s extended-keys on

      bind s setw synchronize-panes # Synchonize panes
      # bind m movew -r # Reorder Windows
      # bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'copy-mode -e; send-keys -M'" # Sane scrolling

      bind c new-window -a # Create a new pane

      # Reload tmux configuration with 'r'. Path is the generated config now;
      # ~/.tmux.conf no longer exists.
      unbind r
      bind r source-file ~/.config/tmux/tmux.conf\; display "Reloading Matrix..."

      # Easier window splitting
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Adjust Split Evenly
      bind v select-layout even-vertical
      bind o select-layout even-horizontal

      # Smart pane switching with awareness of Vim splits.
      # See: https://github.com/christoomey/vim-tmux-navigator
      is_vim="children=(); i=0; pids=( $(ps -o pid= -t '#{pane_tty}') ); \
      while read -r c p; do [[ -n c && c -ne p && p -ne 0 ]] && children[p]+=\" $\{c\}\"; done <<< \"$(ps -Ao pid=,ppid=)\"; \
      while (( $\{#pids[@]\} > i )); do pid=$\{pids[i++]\}; pids+=( $\{children[pid]-\} ); done; \
      ps -o state=,comm= -p \"$\{pids[@]\}\" | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"

      bind-key -n 'C-d' if-shell "$is_vim" "display-message 'In Vim'" "display-message 'Current Command: #{pane_current_command}'"
      bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
      bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
      bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
      bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
      tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
      if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
          "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
      if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
          "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

      if-shell "test -f ~/dotfiles/tmux/tmuxline" "source ~/dotfiles/tmux/tmuxline"
    '';
  };
}
