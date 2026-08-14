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
    # Shared with the WSL box. Anything in here must work on both.
    ../shared/git.nix
    ../shared/shell.nix
    ../shared/tmux.nix
    ../shared/nvim.nix

    # macOS only.
    ./alacritty.nix
    ./karabiner.nix
    ./java.nix
    # Needs pkgs.vscode-marketplace, which the nix-vscode-extensions overlay in
    # flake.nix supplies for this host only.
    ./vscode.nix
    ./git.nix
    ./tmux.nix
    ./shell.nix
    ./launchd.nix
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

    # Load-bearing for a hook this repo already declares.
    # nix/home/darwin/extras.nix sets `session-window-changed` to CLEAR the
    # @claude_alert marker, and this script is what SETS it. Only half of
    # that pair used to be declared, so a fresh machine got the clearing
    # hook and nothing to clear. ~/.claude/settings.json also invokes it by
    # absolute path.
    #
    # Linked rather than generated so it stays editable without a rebuild,
    # and because the rest of ~/.claude is 368 MB of session state that must
    # not be managed.
    ".claude/notify.sh".source = link "claude/notify.sh";

    # Corepack shims. `yarn` is not a global package any more (nix/packages.nix
    # explains why: nixpkgs ships 1.22 Classic), so these two files are what
    # put `yarn` and `pnpm` on PATH. Each resolves whichever version a repo
    # pins in package.json's `packageManager` field.
    #
    # Written as wrappers rather than left to `corepack enable
    # --install-directory`, which symlinks straight into the nodejs store
    # path. That link dangles the first time nodejs_22 advances and the old
    # path is collected, and `yarn` then fails with a missing-file error that
    # points at /nix/store rather than at the upgrade. Resolving `corepack`
    # from PATH at call time survives it.
    #
    # Declared here and not in ../shared/shell.nix, next to the PATH block
    # that makes them reachable, because the WSL host imports that file and
    # omits every language package, nodejs_22 included. A shim there would
    # exec a corepack Linux does not have.
    #
    # ~/.local/bin, not ~/.bin: the latter is an out-of-store symlink to the
    # tracked bin/ directory, and these are generated, not tracked.
    ".local/bin/yarn" = {
      executable = true;
      text = ''
        #!/bin/sh
        exec corepack yarn "$@"
      '';
    };

    ".local/bin/pnpm" = {
      executable = true;
      text = ''
        #!/bin/sh
        exec corepack pnpm "$@"
      '';
    };
  };
}
