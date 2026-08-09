{ ... }:

{
  imports = [ ./packages.nix ];

  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  system.primaryUser = "jose";
  system.stateVersion = 6;

  # zsh-syntax-highlighting ships its files only under
  # /share/zsh-syntax-highlighting, which nix-darwin does not link by
  # default (pathsToLink covers /share/zsh but not this). Without it the
  # package contributes nothing to the profile and drops out of the system
  # closure entirely, even though it evaluates into systemPackages.
  #
  # Not using programs.zsh.enableSyntaxHighlighting: that sources from
  # /etc/zshrc, which runs before ~/.zshrc, and zsh/zshrc requires the
  # plugin to load last.
  environment.pathsToLink = [ "/share/zsh-syntax-highlighting" ];

  # nix-homebrew manages the Homebrew installation itself.
  # This block declares what Homebrew installs.
  homebrew = {
    enable = true;

    # All from homebrew/cask, so no extra taps needed.
    casks = [
      "1password-cli"
      "alacritty"
      "amethyst"
      "android-platform-tools"
      "android-studio"
      "barrier"
      "drawio"
      "iterm2"
      "mactex"
      "ngrok"
      "opensuperwhisper"
      "postman"
      "raycast"
    ];

    # Keep hands off the 243 undeclared formulae until they move to nixpkgs.
    # "uninstall" or "zap" would remove everything not listed above.
    onActivation.cleanup = "none";
  };
}
