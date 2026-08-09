{ pkgs, ... }:

{
  programs.alacritty = {
    enable = true;
    # Alacritty itself comes from the Homebrew cask. `package = null` is
    # supported (the option is declared nullable) and installs nothing,
    # while still writing the config file.
    #
    # Do NOT use `enable = false` here: the module body is wrapped in
    # `lib.mkIf cfg.enable`, so disabling it writes no config at all.
    package = null;
    settings = {
      general = {
        # Do NOT use the module's `theme` option here. With `package = null`
        # it evaluates `cfg.package.version` unguarded and dies with
        # "expected a set but found null" (alacritty.nix:95). The module's
        # own docs point at settings.general.import for this case.
        #
        # Comes from nixpkgs and is versioned by flake.lock, so a fresh
        # clone resolves it. The theme used to be a gitignored git clone
        # under alacritty/, which by definition was never reproducible.
        import = [
          "${pkgs.alacritty-theme}/share/alacritty-theme/seashells.toml"
        ];
        # Boolean, and under [general]. The hand-written TOML this replaced
        # had it stranded under [env] with no table header, so it parsed as
        # env.live_config_reload = "true" (a string) and never worked.
        live_config_reload = true;
      };
      env.TERM = "alacritty";
      font = {
        size = 16;
        normal.family = "FiraCode Nerd Font Mono";
        bold.style = "Regular";
        glyph_offset.y = 7;
        offset.y = 12;
      };
      window = {
        decorations = "Full";
        dynamic_padding = true;
        padding = { x = 0; y = 0; };
      };
      terminal.shell = {
        program = "/bin/zsh";
        args = [ "-l" "-c" "tmux attach || tmux" ];
      };
    };
  };
}
