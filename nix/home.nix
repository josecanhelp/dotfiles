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

  programs.git = {
    enable = true;
    userName = "Jose Soto";
    userEmail = "josecanhelp@gmail.com";
    # Generates the entire [filter "lfs"] block.
    lfs.enable = true;
    # Writes ~/.config/git/ignore, which git reads via XDG. This replaces
    # ~/.gitignore_global, which was never tracked in this repo and would
    # be missing on a new machine. core.excludesfile is dropped, not
    # repointed, because it hardcoded /Users/jose.
    ignores = [
      ".DS_Store"
      ".vscode/*"
      ".secrets"
      "CLAUDE.md"
      "scratch*.md"
      "**/.claude/settings.local.json"
    ];
    extraConfig = {
      github.user = "josecanhelp";
      init.defaultBranch = "main";
      pull.rebase = false;
      color.ui = "auto";
      status.short = true;
      help.autocorrect = 1;
      core.editor = "vim";
      credential.helper = "osxkeychain";
      mergetool = {
        prompt = false;
        keepBackup = false;
      };
      # Percent signs are literal in Nix, but keep this on one line so the
      # colour codes are not broken by wrapping.
      format.pretty = "format:%Cblue%h%Creset %Creset%Cgreen%cn, %cr%Creset : %s%Creset%C(red)%d%Creset";
    };
  };

  programs.starship = {
    enable = true;
    # Adds the init line to the .zshrc home-manager will own in Task 3.
    # Until then it is inert, because zshrc is still hand-written.
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      command_timeout = 500;
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
      package.disabled = true;
      aws.disabled = true;
      python = {
        symbol = "🐍 ";
        # Nix indented string: backslashes stay literal, matching the TOML
        # single-quoted original. A double-quoted Nix string would treat
        # \( as an escape and silently change the prompt.
        format = ''via [$symbol$version( \($virtualenv\))]($style) '';
        style = "yellow bold";
        detect_files = [
          "pyproject.toml"
          ".python-version"
          "uv.lock"
          "requirements.txt"
          "Pipfile"
        ];
        detect_folders = [ ".venv" ];
      };
      nodejs.symbol = "⬢ ";
      conda = {
        format = "[$symbol$environment](dimmed green) ";
        symbol = "🅒 ";
      };
    };
  };

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
        # Versioned by flake.lock. Replaces the import of
        # alacritty/alacritty-theme/, a gitignored clone that would not
        # exist on a new machine.
        import = [
          "${pkgs.alacritty-theme}/share/alacritty-theme/seashells.toml"
        ];
        # Boolean, and under [general]. In the source TOML this line sits
        # after [env] with no table header, so it parsed as
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
