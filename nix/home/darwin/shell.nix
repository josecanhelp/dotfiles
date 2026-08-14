{ config, lib, ... }:

{
  programs.zsh = {
    # ~/.zprofile, login shells only, before .zshrc.
    profileExtra = ''
      # Set PATH, MANPATH, etc., for Homebrew.
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';

    sessionVariables.ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX = "YES";

    # pbcopy is macOS only.
    shellAliases.gdesc = "git log --no-merges --pretty=format:'- %s' master.. | pbcopy";

    initContent = lib.mkMerge [
      # Keep this at 501 so Docker completions are installed before compinit,
      # while avoiding a priority tie with the shared shell module.
      (lib.mkOrder 501 ''
        fpath=(${config.home.homeDirectory}/.docker/completions $fpath)
      '')

      # This block intentionally stays whole because its portable and macOS-only
      # lines are interleaved. Linux carries its portable subset separately.
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
      '')

      # This must run after the shared PATH block so Nix remains ahead of
      # Homebrew, whose shellenv runs in .zprofile.
      (lib.mkOrder 1600 ''
        export PATH="/run/current-system/sw/bin:$PATH"
      '')
    ];
  };
}
