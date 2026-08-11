{ config, lib, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  imports = [
    # The same four modules the Mac uses. Task 2 removed everything
    # macOS-specific from them.
    ../shared/git.nix
    ../shared/shell.nix
    ../shared/tmux.nix
    ../shared/nvim.nix
  ];

  # Standalone home-manager needs these three explicitly. On the Mac they come
  # from nix-darwin via users.users.<name>.home and system.primaryUser.
  home.username = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  # /bin/zsh, shared/tmux.nix's old default, is Apple's system zsh and does
  # not exist on Linux; a fresh WSL image has no zsh at all. tmux given a
  # nonexistent default-shell refuses to start ("not a suitable shell")
  # rather than falling back, so this must point at the Nix-installed zsh
  # instead.
  programs.tmux.shell = "${pkgs.zsh}/bin/zsh";

  # Terminal dev core. The Mac declares 51 packages through
  # environment.systemPackages, which is a nix-darwin option, so this list is
  # written fresh rather than shared.
  #
  # Deliberately absent: coreutils (Linux already has GNU coreutils, unlike
  # macOS), goku (drives Karabiner), jadx, inetutils, nmap, pandoc, typst,
  # ranger, joker, yt-dlp, uv, shopify-cli, stripe-cli, and everything in the
  # media, vendored, languages and services groups.
  home.packages = with pkgs; [
    actionlint
    btop
    # fzf is not listed: programs.fzf in shared/shell.nix already adds it to
    # this same home.packages. On darwin the duplicate is across two profiles
    # and harmless; here it would be the same list twice.
    gh
    git-filter-repo
    htop
    jq
    pstree
    ripgrep
    tree
    watchexec
    wget
  ];

  # git-wtf and zsh-colors, both portable shell scripts. The Mac's other
  # linked files are macOS-specific or depend on osascript.
  home.file.".bin".source = link "bin";

  # The four portable items from the Mac's mkOrder 1100 block, copied rather
  # than shared. See darwin/extras.nix for why that block did not split: two of
  # its six items are macOS-only and interleaved with these, so splitting it
  # would have reordered the Mac's generated .zshrc.
  programs.zsh.initContent = lib.mkOrder 1100 ''
    zstyle ':completion:*' verbose yes
    zstyle ':completion:*' menu select
    zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
    zmodload zsh/complist
    _comp_options+=(globdots)

    bindkey -v '^?' backward-delete-char
    bindkey -M menuselect 'h' vi-backward-char
    bindkey -M menuselect 'k' vi-up-line-or-history
    bindkey -M menuselect 'l' vi-forward-char
    bindkey -M menuselect 'j' vi-down-line-or-history

    autoload edit-command-line; zle -N edit-command-line
    bindkey '^e' edit-command-line
  '';
}
