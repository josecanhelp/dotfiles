{ config, lib, pkgs, ... }:

{
  # The macOS half of the shared modules. Kept here rather than behind
  # `lib.mkIf pkgs.stdenv.isDarwin` guards inside each shared module, so that
  # "is this shared?" is answered by the file path.
  #
  # macOS keychain. Does not exist on Linux, where git will prompt instead.
  programs.git.settings.credential.helper = "osxkeychain";

  # The whole notification block, moved as one unit from the TAIL of
  # shared/tmux.nix's extraConfig. Moving it whole is what preserves the
  # generated tmux.conf byte-for-byte: it was the last thing in extraConfig, so
  # appending it with mkAfter reproduces the original order exactly.
  #
  # Moving only the osascript line would have reordered the file, because that
  # line sits BEFORE the session-window-changed hook, and mkAfter would have
  # put it after. That would change the system hash.
  #
  # The whole block is darwin-specific even though bell-action and visual-bell
  # are portable tmux settings: they exist to support the osascript
  # notification, and session-window-changed clears a marker that
  # ~/.claude/notify.sh sets, which is itself macOS-only.
  programs.tmux.extraConfig = lib.mkAfter ''
    # Fire macOS notification when any pane rings the bell (e.g. Claude Code)
    set -g bell-action any
    set -g visual-bell off
    set-hook -g alert-bell 'run-shell "osascript -e \"display notification \\\"Claude requires your attention\\\" with title \\\"Claude Code\\\"\""'

    # Clear the Claude attention marker (@claude_alert) the moment its window is
    # focused. The marker itself is set by ~/.claude/notify.sh (Claude Code hooks).
    set-hook -g session-window-changed 'set-option -w @claude_alert ""'
  '';

  programs.zsh = {
    # ~/.zprofile, login shells only. The whole reason /opt/homebrew/bin is on
    # PATH. brew shellenv PREPENDS, so the mkOrder 1600 block below is what
    # takes precedence back for Nix.
    profileExtra = ''
      # Set PATH, MANPATH, etc., for Homebrew.
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';

    sessionVariables.ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX = "YES";

    # pbcopy is macOS only.
    shellAliases.gdesc = "git log --no-merges --pretty=format:'- %s' master.. | pbcopy";

    initContent = lib.mkMerge [
      # Deliberately not lib.mkBefore (mkOrder 500), which is what the shared
      # block below also uses. Two mkOrder-500 blocks tie, and ties are
      # broken by module encounter order, not by import-list position; in
      # this tree that resolved with this block BEFORE the shared secrets
      # line, reversed from the original single-block source order (secrets,
      # then fpath) and enough to change the generated .zshrc and the system
      # hash. mkOrder 501 keeps this ahead of compinit (unprioritized 1000)
      # while breaking the tie so it still lands after the shared block.
      (lib.mkOrder 501 ''
        # MUST be before compinit, which home-manager's enableCompletion
        # runs early in the generated .zshrc. In the original zshrc this
        # line sat immediately before a second manual compinit; that second
        # call existed precisely to pick these up. fpath mutations after
        # compinit are ignored, so `docker <TAB>` would silently stop
        # completing. home-manager's own `typeset -U ... fpath` de-dupes
        # rather than resets, so prepending here is safe.
        fpath=(${config.home.homeDirectory}/.docker/completions $fpath)
      '')

      # This entire block is verbatim from the pre-split shared/shell.nix, at
      # the same mkOrder, deliberately NOT split along platform lines.
      #
      # Two of its six items are macOS-only (the functions.zsh source, whose
      # functions call `open`, and the aws_completer path under /usr/local),
      # and they are interleaved with the four portable ones. Splitting the
      # block would reorder the generated .zshrc and change the system hash,
      # so the whole thing stays here and linux/default.nix carries its own
      # copy of the four portable items instead.
      (lib.mkOrder 1100 ''
        source $HOME/dotfiles/zsh/custom/functions.zsh

        zstyle ':completion:*' verbose yes
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
        zmodload zsh/complist
        _comp_options+=(globdots)

        autoload bashcompinit && bashcompinit
        complete -C '/usr/local/bin/aws_completer' aws

        bindkey -v '^?' backward-delete-char
        bindkey -M menuselect 'h' vi-backward-char
        bindkey -M menuselect 'k' vi-up-line-or-history
        bindkey -M menuselect 'l' vi-forward-char
        bindkey -M menuselect 'j' vi-down-line-or-history

        autoload edit-command-line; zle -N edit-command-line
        bindkey '^e' edit-command-line

        eval "$(fzf --zsh)"
      '')

      # 1600, above the shared mkAfter block's 1500. This must run LAST of all
      # PATH manipulation or Homebrew wins: brew shellenv in profileExtra above
      # prepends /opt/homebrew/bin, and this is what takes precedence back.
      #
      # /run/current-system/sw/bin is a nix-darwin path and does not exist on
      # Linux, which is why this line cannot live in the shared module.
      (lib.mkOrder 1600 ''
        # Nix must win over Homebrew. brew shellenv in ~/.zprofile prepends
        # /opt/homebrew/bin. This runs last, so it wins.
        #
        # ~/.nix-profile/bin is deliberately absent. It is a dangling symlink
        # here, and correctly so: configuration.nix sets
        # home-manager.useUserPackages, which installs home-manager packages
        # into /etc/profiles/per-user/$USER instead. That directory is already
        # on PATH. The old entry resolved to nothing and only misled anyone
        # reading this line while debugging PATH.
        export PATH="/run/current-system/sw/bin:$PATH"
      '')
    ];
  };

  # Open Alacritty fullscreen with the restored session at login.
  #
  # The script drives osascript and System Events keystrokes, so it needs
  # Accessibility permission. macOS keys that approval to some process, and
  # the installed plist wraps the script as `/bin/sh -c "/bin/wait4path
  # /nix/store && exec <store path> fullscreen"`, so the process TCC
  # attributes the approval to may be /bin/sh rather than the store path
  # itself. Unverified either way; a continuum update that changes the store
  # path may require re-approving under System Settings, Privacy and
  # Security, Accessibility.
  #
  # home-manager's activation only skips re-bootstrapping an agent when the
  # installed plist byte-matches the new one. Otherwise it boots the old one
  # out and loads the new one, and because RunAtLoad is true here, the script
  # runs immediately, mid-activation, during `darwin-rebuild switch`. So the
  # next nixpkgs bump that moves tmuxPlugins.continuum's store path will,
  # mid-rebuild, activate Alacritty, keystroke "tmux" and Return into the
  # front window, and toggle AXFullScreen, which can nest tmux inside the
  # session you are rebuilding from and un-fullscreen an already fullscreen
  # window. Continuum's own plist never did this, because it was written at
  # tmux-server start, not at activation.
  launchd.agents.tmux-boot = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/scripts/handle_tmux_automatic_start/osx_alacritty_start_tmux.sh"
        "fullscreen"
      ];
      RunAtLoad = true;
    };
  };
}
