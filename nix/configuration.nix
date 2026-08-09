{ pkgs, ... }:

{
  imports = [ ./packages.nix ];

  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  # nixpkgs.hostPlatform is set per host by mkHost in flake.nix, so this
  # module stays architecture-agnostic.

  system.primaryUser = "jose";
  system.stateVersion = 6;

  # home-manager derives home.homeDirectory from users.users.<name>.home,
  # which nix-darwin otherwise leaves null (system.primaryUser alone does
  # not populate it). Without this, evaluation fails with "A definition
  # for option `home-manager.users.jose.home.homeDirectory' is not of type
  # `absolute path'". Not added to users.knownUsers: that would make
  # nix-darwin try to create/manage the account, and jose already exists.
  users.users.jose.home = "/Users/jose";

  # home-manager manages files in $HOME. nix-darwin manages the machine.
  # useGlobalPkgs makes it share this system's nixpkgs instead of
  # instantiating a second one.
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # Moves a pre-existing file aside instead of aborting activation.
    # Note this only works for regular files: check-link-targets.sh guards
    # on `! -L`, so an existing SYMLINK is never backed up and activation
    # fails with "would be clobbered". Delete conflicting symlinks by hand.
    backupFileExtension = "hm-bak";
    users.jose = import ./home;
  };

  # programs.alacritty in nix/home.nix hard-requires "FiraCode Nerd Font
  # Mono". Without this it was only present as a manual install in
  # ~/Library/Fonts, so a fresh machine rendered every prompt glyph as a
  # box. The other ~289 fonts there are design assets, not terminal
  # dependencies, and stay unmanaged.
  fonts.packages = with pkgs; [ nerd-fonts.fira-code ];

  # macOS settings that previously existed only in this machine's
  # preference database. Every value below was read off the running system
  # rather than chosen, so activation is a no-op today.
  #
  # Note these are now enforced: change one in System Settings and the next
  # `darwin-rebuild switch` puts it back. Change it here instead.
  system.defaults = {
    dock = {
      autohide = true;
      tilesize = 36;
      mru-spaces = false;      # required by Amethyst; stops spaces reordering
      wvous-br-corner = 5;     # bottom-right hot corner starts the screen saver
    };

    finder = {
      ShowPathbar = true;
      FXPreferredViewStyle = "Nlsv";   # list view
      _FXSortFoldersFirst = true;
      ShowHardDrivesOnDesktop = true;
    };

    NSGlobalDomain = {
      # Fast key repeat. Below macOS's own slider minimum, and the first
      # thing you would notice missing on a new machine.
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      # Off means holding a key repeats it instead of showing the accent
      # picker, which is what makes vim navigation usable.
      ApplePressAndHoldEnabled = false;
      AppleShowAllExtensions = true;
    };

    screencapture.location = "~/Screenshots";
  };

  # nix-homebrew manages the Homebrew installation itself.
  # This block declares what Homebrew installs.
  homebrew = {
    enable = true;

    # Third-party taps. `brew leaves` does not list formulae from these,
    # which is why the packages migration never saw them. Declared here so
    # a fresh machine reproduces them.
    taps = [
      "shopify/shopify"
      "masaushi/tap"
      "microsoft/mssql-release"
    ];

    # Not in nixpkgs, so they stay on Homebrew rather than going
    # undeclared. Everything else from these taps (goku, stripe-cli,
    # shopify-cli) moved to nix/packages.nix.
    brews = [
      "themekit"      # shopify/shopify
      "ecsplorer"     # masaushi/tap
      "msodbcsql17"   # microsoft/mssql-release
    ];

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
