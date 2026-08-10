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

  # flake.nix keys its configuration on this hostname, so the rebuild command
  # requires it, but nothing here used to SET it. On a fresh machine
  # `darwin-rebuild switch --flake .#REM-JoseS-MBP1` therefore failed until the
  # name was set by hand first.
  #
  # networking.hostName is deliberately omitted: `scutil --get HostName` is
  # unset on this machine, and setting it would be a behaviour change rather
  # than a capture of what exists.
  #
  # The REM- prefix suggests corporate MDM assigns this name. Declaring it is
  # harmless while MDM agrees, and will fight MDM if IT ever renames the
  # machine. If that happens, this is the line to look at.
  networking.computerName = "REM-JoseS-MBP1";
  networking.localHostName = "REM-JoseS-MBP1";

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

  # programs.alacritty in nix/home/alacritty.nix hard-requires "FiraCode Nerd
  # Mono". Without this it was only present as a manual install in
  # ~/Library/Fonts, so a fresh machine rendered every prompt glyph as a
  # box. The other ~289 fonts there are design assets, not terminal
  # dependencies, and stay unmanaged.
  fonts.packages = with pkgs; [ nerd-fonts.fira-code ];

  # Cap ~/Library/Logs/goku.log, written by launchd.agents.goku in
  # nix/home/karabiner.nix. That log reached 74 MB and 4.3 million lines
  # before this sub-project, because the old Homebrew agent had
  # KeepAlive = true and its binary was missing, so launchd respawned a
  # failing job every 10 seconds and every respawn appended.
  #
  # Rotation matches that failure mode specifically. launchd opens the
  # StandardErrorPath once per spawned process, so a single healthy
  # watchexec holds its descriptor and would keep writing to an already
  # rotated file. That case does not matter: a working watcher logs almost
  # nothing. The runaway case is many short-lived respawns, and each of
  # those reopens the path, so rotation does bound it.
  #
  # This lives here rather than beside the agent because environment.etc is
  # a nix-darwin option and /etc is machine-level; home-manager cannot
  # write it. Fields: mode, archive count, size in KB, when, flags.
  # N means no process needs signalling, J compresses with bzip2.
  environment.etc."newsyslog.d/goku.conf".text = ''
    # logfilename                       [owner:group]  mode count size when flags
    /Users/jose/Library/Logs/goku.log    jose:staff     644  3     1024 *    NJ
  '';

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
    ];

    # Not in nixpkgs, so they stay on Homebrew rather than going
    # undeclared. Everything else from these taps (goku, stripe-cli,
    # shopify-cli) moved to nix/packages.nix.
    brews = [
      "themekit"      # shopify/shopify
      "ecsplorer"     # masaushi/tap
      # The exceptions documented in nix/packages.nix. They were described
      # there but never declared anywhere, so `brew leaves` and this list were
      # disjoint sets and a fresh machine installed none of them.
      #
      # pytorch is deliberately still absent: packages.nix argues it is heavy
      # and rarely wanted globally, and a devshell is the right home. Leaving
      # it undeclared makes that argument true rather than merely stated.
      "ant"           # apacheAnt evaluates unavailable on aarch64-darwin
      "pipx"          # fails its checkPhase in this nixpkgs
      "ruby"          # keg-only and unlinked, so /usr/bin/ruby still wins
    ];

    # All from homebrew/cask, so no extra taps needed.
    # Every token here was checked against the Homebrew cask index before being
    # added. A wrong token does not fail the build, it fails at activation,
    # which is a slower and more annoying way to find out.
    #
    # Declaring an app Homebrew did not install is NOT free, which is worth
    # knowing before adding to this list. Homebrew tries to "adopt" the
    # existing bundle and refuses when the installed version differs from the
    # cask's, so any app that self-updated after being downloaded directly
    # fails with "It seems the existing App is different from the one being
    # installed". On 2026-08-10 that hit balenaetcher and bambu-studio, and
    # obsidian failed worse: adoption removed /Applications/Obsidian.app before
    # erroring, so the app had to be reinstalled. Resolve each by letting
    # Homebrew take ownership once, with `brew install --cask --force <token>`,
    # after which normal upgrades work.
    #
    # onActivation.cleanup = "none" below only stops Homebrew UNINSTALLING
    # things that are not declared. It does not make installing a no-op.
    #
    # 16 installed apps were deliberately NOT declared on 2026-08-10, after
    # review: Cap, Cyberduck, ScreenFlow, Visual Studio, Discord,
    # ResponsivelyApp, cool-retro-term, DBeaver, Eclipse, MySQLWorkbench,
    # Raspberry Pi Imager, Sketch, Tunnelblick, NordVPN, VirtualBox and
    # DisplayLink Manager. They stay installed; they just will not follow to a
    # new machine. Visual Studio for Mac is discontinued upstream anyway.
    #
    # barrier and drawio were removed the same day. Both apps had been deleted
    # outside Homebrew, so Homebrew still recorded them as installed and
    # activation was a no-op, while a fresh machine would have resurrected two
    # unused apps. Barrier's upstream is unmaintained; Deskflow and Input Leap
    # are its successors.
    casks = [
      "1password"                  # the GUI app; 1password-cli below is separate
      "1password-cli"
      "alacritty"
      "amethyst"
      "android-platform-tools"
      "android-studio"
      "balenaetcher"
      "bambu-studio"
      "brave-browser"
      "chatgpt"
      "claude"
      "codex-app"                  # token is codex-app, not codex
      "dbngin"
      "docker-desktop"             # token is docker-desktop, not docker
      "dropbox"
      "epic-games"                 # a separate `epic` cask is a different product
      "figma"
      "firefox@developer-edition"  # the @ is part of the token
      "fork"
      "google-chrome"
      "hammerspoon"                # its config is already linked in nix/home
      "handbrake-app"              # plain `handbrake` is the CLI formula
      "imageoptim"
      # Likely deployed by Intune. Declaring it may fight the MDM channel; if
      # activation starts failing on this line, that is why.
      "intune-company-portal"
      "istat-menus"
      "izotope-product-portal"     # installs RX; RX itself has no cask
      # Pairs with the declared goku and the karabiner.edn links in
      # nix/home/karabiner.nix. Previously the config was declared and the app
      # was not, so a fresh machine got the keymap and nothing to read it.
      # Karabiner-EventViewer ships inside this cask; do not add it separately.
      "karabiner-elements"
      "iterm2"
      "ledger-wallet"              # token is ledger-wallet, not ledger-live
      "local"
      "mactex"
      "microsoft-office"           # one cask, five apps: Word/Excel/PPT/OneNote/Outlook
      "microsoft-teams"
      "minecraft"
      "monologue"
      "ngrok"
      "obs"
      "obsidian"
      # onedrive is deliberately absent. The cask declares a conflict with
      # microsoft-office above, which is a pkg installer for the whole 365
      # suite and ships OneDrive itself, so declaring both fails activation
      # with "Cask 'onedrive' conflicts with 'microsoft-office'".
      #
      # Note there are still two OneDrive installs on disk: the one Office
      # manages, and an older Mac App Store copy under
      # /Applications/OneDrive.localized/. That duplicate predates this config.
      "openshot-video-editor"
      "opensuperwhisper"
      "postman"
      "raycast"
      "shottr"
      "sizzy"
      "slack"
      "sublime-text"
      "tableplus"
      "transmit"
      "trezor-suite"
      "visual-studio-code"
      "vlc"                        # not in nixpkgs for aarch64-darwin
      "wireshark-app"              # token is wireshark-app for the GUI
      "zoom"                       # token is zoom, not zoom.us
    ];

    # Keep hands off the 243 undeclared formulae until they move to nixpkgs.
    # "uninstall" or "zap" would remove everything not listed above.
    onActivation.cleanup = "none";
  };
}
