{ config, pkgs, lib, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
  # Out-of-store symlink: points at the live repo, so edits take effect
  # immediately with no rebuild. A plain `source = ./path` would copy into
  # /nix/store and make the file read-only.
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  home.stateVersion = "26.05";

  # XDG is off by default on darwin. Without this, every xdg.configFile
  # entry below silently does nothing.
  xdg.enable = true;

  home.file = {
    ".tmux.conf".source = link "tmux.conf";
    # tpm writes plugins/ here, so it must stay out-of-store.
    ".tmux".source = link "tmux";
    # Hammerspoon writes Spoons/ here.
    ".hammerspoon".source = link "hammerspoon";
    ".amethyst.yml".source = link "amethyst/amethyst.yml";
    ".hushlogin".source = link "hushlogin";
    ".bin".source = link "bin";
  };

  xdg.configFile = {
    # lazy.nvim writes lazy-lock.json here.
    "nvim".source = link "nvim";
    # Linked to both paths because that is goku's search path. Preserved
    # exactly as dotbot had it.
    "karabiner.edn".source = link "karabiner/karabiner.edn";
    "karabiner/karabiner.edn".source = link "karabiner/karabiner.edn";
  };
}
