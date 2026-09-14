{ ... }:

{
  programs.ghostty = {
    enable = true;
    # Ghostty itself comes from the Homebrew cask (nix/configuration.nix), same
    # arrangement alacritty.nix used. `package = null` is supported (the option
    # is typed "null or package") and installs nothing, while still writing the
    # config file.
    #
    # Do NOT use `enable = false` here. As with the alacritty module, the body is
    # wrapped in `lib.mkIf cfg.enable`, so disabling it writes no config at all.
    #
    # nixpkgs also carries ghostty 1.3.1, the same version as the stable cask, so
    # switching this to a real package later is a one-line change if you want the
    # flake to own the app outright instead of Homebrew.
    package = null;

    # Transcribed verbatim from the hand-written ~/.config/ghostty/config that
    # predates this module, with one addition (shell-integration-features). These
    # values are NOT ported from alacritty.nix: that config kept its own font,
    # theme and padding, and is archived rather than migrated.
    #
    # Every key here was validated against the installed binary with
    # `ghostty +validate-config`. Note that command exits 0 whether or not the
    # config is valid, so its OUTPUT is the signal; an unknown key prints
    # "unknown field" and a bad value prints "invalid value".
    settings = {
      theme = "retroma-teal";

      font-family = "MonoLisa";
      font-size = 16;

      window-padding-x = 10;
      window-padding-y = 10;

      cursor-style = "block";
      cursor-style-blink = false;

      # ADDED here, not carried over from the hand-written config.
      #
      # Ghostty's default feature list contains `no-ssh-terminfo`, which means a
      # remote host never learns the xterm-ghostty terminfo entry and renders the
      # session badly. `ssh-terminfo` makes ghostty install it on connect, and
      # `ssh-env` propagates the matching TERM. The remaining four (cursor,
      # no-sudo, title, path) are ghostty's own defaults, restated because this
      # setting replaces the list rather than appending to it.
      shell-integration-features = "ssh-terminfo,ssh-env,cursor,no-sudo,title,path";
    };

    # Transcribed from ~/.config/ghostty/themes/retroma-teal. The original file
    # carried a provenance header the generated output cannot keep, because the
    # key-value writer emits only keys, so it is preserved here instead:
    #
    #   Retroma Teal (dark) - generated from Retroma's OKLCh harmony method
    #   base accent: teal / harmony: analogous
    #
    # `palette` is a LIST because the theme sets that key sixteen times. The
    # module types each theme as an attribute set of atoms "or a list of them for
    # duplicate keys", and the list form is what produces the repeated lines.
    themes.retroma-teal = {
      palette = [
        "0=#214d47"
        "1=#ff9186"
        "2=#7ccb7c"
        "3=#e4a942"
        "4=#74bbff"
        "5=#dc97e9"
        "6=#13d0bd"
        "7=#e3eeec"
        "8=#4b6d68"
        "9=#ffcec8"
        "10=#a2f3a2"
        "11=#ffd491"
        "12=#c0dfff"
        "13=#f7c9ff"
        "14=#59f8e4"
        "15=#eff7f5"
      ];

      background = "#003630";
      foreground = "#e3eeec";
      cursor-color = "#09eed8";
      cursor-text = "#003630";
      selection-background = "#035951";
      selection-foreground = "#e1f3f0";
    };
  };
}
