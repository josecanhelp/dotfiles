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
  };
}
