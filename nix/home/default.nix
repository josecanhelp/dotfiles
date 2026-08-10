{ config, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
  # Out-of-store symlink: points at the live repo, so edits take effect
  # immediately with no rebuild. A plain `source = ./path` would copy into
  # /nix/store and make the file read-only.
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  imports = [
    ./git.nix
    ./shell.nix
    ./alacritty.nix
    ./tmux.nix
    ./nvim.nix
    ./karabiner.nix
    ./java.nix
  ];

  home.stateVersion = "26.05";

  # XDG is off by default on darwin. This has no consumer in this file: the
  # xdg.configFile entries it enables now live in karabiner.nix. That
  # cross-file coupling is the one real cost of splitting karabiner out into
  # its own module, so if this line ever moves or gets deleted, the failure
  # shows up over there, not here.
  xdg.enable = true;

  home.file = {
    # Hammerspoon writes Spoons/ here.
    ".hammerspoon".source = link "hammerspoon";
    ".amethyst.yml".source = link "amethyst/amethyst.yml";
    ".hushlogin".source = link "hushlogin";
    ".bin".source = link "bin";

    # Load-bearing for a hook this repo already declares. nix/home/tmux.nix
    # sets `session-window-changed` to CLEAR the @claude_alert marker, and
    # this script is what SETS it. Only half of that pair used to be
    # declared, so a fresh machine got the clearing hook and nothing to
    # clear. ~/.claude/settings.json also invokes it by absolute path.
    #
    # Linked rather than generated so it stays editable without a rebuild,
    # and because the rest of ~/.claude is 368 MB of session state that must
    # not be managed.
    ".claude/notify.sh".source = link "claude/notify.sh";
  };
}
