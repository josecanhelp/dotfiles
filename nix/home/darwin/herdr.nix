{ config, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  # herdr is the terminal workspace manager that replaced tmux on 2026-09-12.
  #
  # There is no `programs.herdr` home-manager module and no nixpkgs package, so
  # the file is linked rather than generated. It is also exactly the kind of
  # config the conventions reserve for mkOutOfStoreSymlink: hand-edited often,
  # and written by its owning tool (`herdr config reset-keys` rewrites
  # config.toml in place after backing it up to config.toml.pre-keys). Because
  # the link is out of store, that write lands in the repo and shows up as a
  # normal diff instead of failing against a read-only /nix/store path.
  #
  # The BINARY is deliberately not declared anywhere in this repo. herdr
  # installs and updates itself into ~/.local/bin via `herdr update`, on a
  # stable/preview channel it tracks on its own, so a fresh machine needs that
  # bootstrap by hand. This is a real gap against the "declare what matters"
  # rule, kept open only because nix has nothing to install yet.
  xdg.configFile = {
    # The single FILE, never the directory. ~/.config/herdr also holds herdr's
    # runtime state: herdr.sock and herdr-client.sock, the two server and
    # client logs, session.json and .plugins.lock. Managing the directory would
    # put all of that behind a store path the daemon cannot write.
    #
    # Edits need `herdr server reload-config` to reach the running server, the
    # same as the keybindings documented in docs/keyboard-workflow.md.
    "herdr/config.toml".source = link "herdr/config.toml";
  };
}
