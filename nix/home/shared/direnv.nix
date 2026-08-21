{ ... }:

{
  # Enters a directory's Nix devShell on cd and leaves it on cd out, so a
  # project's toolchain is present without typing `nix develop`. Inert
  # everywhere except directories holding an .envrc that has been through
  # `direnv allow`, so enabling it changes nothing about existing shells.
  #
  # Added for the build123d environment in ~/Code/3d-designs/soto-3d-designs,
  # which pins CPython 3.13 and uv through a flake because build123d's
  # OpenCascade dependency is not in nixpkgs and only exists as a 224 MB wheel.
  programs.direnv = {
    enable = true;

    # Writes the hook into the .zshrc that programs.zsh generates. Without
    # this, direnv is installed but never activates in a shell. Same caveat as
    # starship and fzf in shared/shell.nix: it works only because
    # programs.zsh owns that file.
    enableZshIntegration = true;

    # Replaces direnv's stock `use flake` with nix-direnv's. Both accept the
    # same one-line .envrc, and they differ in two ways that are felt daily:
    #
    #   1. Stock direnv re-runs `nix print-dev-env` on every entry, which is a
    #      full flake evaluation. nix-direnv caches the resulting environment
    #      and re-evaluates only when flake.nix or flake.lock changes.
    #   2. nix-direnv plants a gc root for each cached shell, so `nix store gc`
    #      cannot collect a project's toolchain out from under it.
    nix-direnv.enable = true;

    # direnv otherwise prints every variable it adds and removes on entry,
    # which for a Nix devShell is a screenful of store paths. This keeps the
    # "direnv: loading" line and drops the diff.
    config.global.hide_env_diff = true;
  };
}
