{ hostname, user, lib, pkgs, ... }:

let
  # hostname and user come from mkHost in flake.nix. Adding a machine means
  # adding one block there, not editing literals in here. Everything below
  # that used to hardcode "jose" or "/Users/jose" derives from these two.
  homeDir = "/Users/${user}";
in
{
  imports = [ ./packages.nix ];

  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  # nixpkgs.hostPlatform is set per host by mkHost in flake.nix, so this
  # module stays architecture-agnostic.

  system.primaryUser = user;
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
  networking.computerName = hostname;
  networking.localHostName = hostname;

  # home-manager derives home.homeDirectory from users.users.<name>.home,
  # which nix-darwin otherwise leaves null (system.primaryUser alone does
  # not populate it). Without this, evaluation fails with "A definition
  # for option `home-manager.users.jose.home.homeDirectory' is not of type
  # `absolute path'". Not added to users.knownUsers: that would make
  # nix-darwin try to create/manage the account, and jose already exists.
  users.users.${user}.home = homeDir;

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
    users.${user} = import ./home;
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
    ${homeDir}/Library/Logs/goku.log    ${user}:staff  644  3     1024 *    NJ
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
      wvous-tr-corner = 4;     # top-right shows the desktop

      # The Dock's actual contents. Previously undeclared entirely, so a fresh
      # machine got Apple's stock Dock. Order matters and is preserved.
      #
      # Plain strings work here: the option coerces a string to { app = ...; }.
      persistent-apps = [
        "/Applications/Brave Browser.app"
        "/System/Applications/Messages.app"
        "/System/Applications/Photos.app"
        "/System/Applications/System Settings.app"
        "/System/Applications/iPhone Mirroring.app"
        "/Applications/Microsoft Teams.app"
      ];

      # showas and arrangement are enums that nix-darwin maps to the integers
      # macOS stores: showas automatic=0 fan=1 grid=2 list=3, arrangement
      # name=1 date-added=2 date-modified=3 date-created=4 kind=5.
      #
      # These are "fan" and "date-added" because that is what the machine
      # actually has (showas = 1, arrangement = 2). An earlier audit recorded
      # them as grid and name; declaring that would have silently changed both
      # folders on the next rebuild, which is the specific hazard of an
      # enforced setting.
      # Each entry must be tagged `folder = ...` (or `file = ...`). A bare
      # attrset fails to evaluate: only a plain string gets auto-tagged.
      persistent-others = [
        {
          folder = {
            path = "${homeDir}/Screenshots";
            showas = "fan";
            arrangement = "date-added";
            displayas = "stack";
          };
        }
        {
          folder = {
            path = "${homeDir}/Downloads";
            showas = "fan";
            arrangement = "date-added";
            displayas = "stack";
          };
        }
      ];
    };

    # Sequoia's own window features, both off. These matter specifically
    # because Amethyst is the window manager: macOS tiling margins fight
    # Amethyst's layout, and a stray click on the wallpaper throwing every
    # window aside is hostile to a tiling workflow.
    WindowManager = {
      EnableStandardClickToShowDesktop = false;
      EnableTiledWindowMargins = false;
      AutoHide = true;          # the Stage Manager strip stays hidden
      GloballyEnabled = false;  # Stage Manager off; matches the macOS default
    };

    spaces.spans-displays = false;  # each display keeps its own spaces

    finder = {
      ShowPathbar = true;
      FXPreferredViewStyle = "Nlsv";   # list view
      _FXSortFoldersFirst = true;
      _FXSortFoldersFirstOnDesktop = true;
      ShowHardDrivesOnDesktop = true;
      ShowExternalHardDrivesOnDesktop = true;
      ShowRemovableMediaOnDesktop = true;
      FXRemoveOldTrashItems = true;    # empty the Trash after 30 days
      # The friendly enum, not the raw "PfVo" macOS stores. nix-darwin maps it.
      # Stock macOS opens Recents; this opens the startup volume.
      NewWindowTarget = "OS volume";
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
      # Stops a two-finger swipe triggering browser back/forward, which fires
      # by accident far more often than on purpose.
      AppleEnableSwipeNavigateWithScrolls = false;
      # A float, not a string. "0" fails to evaluate against the option type.
      # The alert sound is muted; losing this is immediately obvious.
      "com.apple.sound.beep.volume" = 0.0;
    };

    # The alert sound itself lives in .GlobalPreferences rather than -g.
    # Stock macOS uses Boop.
    ".GlobalPreferences"."com.apple.sound.beep.sound" =
      "/System/Library/Sounds/Tink.aiff";

    screencapture.location = "~/Screenshots";

    # Two whole-value writes that nix-darwin has no typed option for. Safe
    # here precisely BECAUSE they are whole-value: CustomUserPreferences emits
    # a plain `defaults write <domain> <key> <value>`, which replaces the key.
    # That is fine for a key you own entirely, and destructive for one you
    # share. See the activation script below for the case where it is not safe.
    CustomUserPreferences = {
      # Text replacements, the ones System Settings calls Text Replacements.
      # "with" needs quoting: it is a Nix keyword, and unquoted it is a
      # syntax error rather than an attribute name.
      NSGlobalDomain.NSUserDictionaryReplacementItems = [
        { on = 1; replace = "omw"; "with" = "On my way!"; }
        { on = 1; replace = "heroky"; "with" = "heroku"; }
      ];
      # Stop macOS offering to turn on Dictation. nix-darwin's `hitoolbox`
      # scope exists but exposes only AppleFnUsageType, so this goes here.
      "com.apple.HIToolbox".AppleDictationAutoEnable = 0;
    };
  };

  # Keyboard shortcuts that are deliberately DISABLED, so the keys are free
  # for Karabiner, Hammerspoon and tmux to claim.
  #
  # These cannot use system.defaults.CustomUserPreferences, and the reason
  # matters. That option emits one `defaults write <domain> <key> <value>` per
  # key, which REPLACES the value. AppleSymbolicHotKeys is a single dictionary
  # holding all 33 of this machine's shortcut entries, so declaring the 8 below
  # through it would write a dictionary containing only those 8 and silently
  # destroy the other 25. `-dict-add` merges instead.
  #
  # An earlier note suggested system.activationScripts.postUserActivation for
  # this. That option no longer exists: nix-darwin asserts on it, because all
  # activation now runs as root. Hence postActivation plus the same
  # `launchctl asuser ... sudo --user=` wrapper nix-darwin itself uses for
  # user-domain defaults, so the writes land in jose's preferences and not
  # root's.
  #
  # Values were read from the live plist rather than reconstructed. Parameters
  # are (key code, keyboard code, modifier mask).
  #
  # The value is written as an XML plist rather than the shorter
  # `{enabled=0;value={parameters=(51,20,1179648);...};}` syntax, because that
  # short form is silently lossy: `defaults` stores enabled as integer 0 and
  # the parameters as STRINGS, where macOS itself writes boolean false and
  # integers. Verified by writing one entry both ways and comparing types
  # against an untouched entry. XML round-trips exactly.
  #
  # New machines need a logout, or `killall SystemUIServer`, before the
  # keyboard daemon rereads these. On this machine the values already match,
  # so activation is a no-op.
  system.activationScripts.postActivation.text =
    let
      inherit user;
      # 28/29: Cmd-Shift-3 and Cmd-Ctrl-Shift-3, full-screen screenshot
      # 30/31: Cmd-Shift-4 and Cmd-Ctrl-Shift-4, selection screenshot
      #        All four off in favour of Shottr.
      # 52:    Cmd-Opt-D, hide the Dock. Reclaimed.
      # 60/61: Ctrl-Space and Ctrl-Opt-Space, cycle input sources. Off so
      #        Ctrl-Space is free.
      # 190:   Quick Note hot corner. Off so the corner does not fire.
      #
      # Parameters are (key code, keyboard code, modifier mask).
      hotkeys = {
        "28" = [ 51 20 1179648 ];
        "29" = [ 51 20 1441792 ];
        "30" = [ 52 21 1179648 ];
        "31" = [ 52 21 1441792 ];
        "52" = [ 100 2 1572864 ];
        "60" = [ 32 49 262144 ];
        "61" = [ 32 49 786432 ];
        "190" = [ 113 12 8388608 ];
      };
      paramsXml = params:
        lib.concatMapStrings (p: "<integer>${toString p}</integer>") params;
      disable = id: params: ''
        launchctl asuser "$(id -u -- ${user})" sudo --user=${user} -- \
          defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add ${id} \
          '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array>${paramsXml params}</array><key>type</key><string>standard</string></dict></dict>'
      '';
    in
    lib.concatStrings (lib.mapAttrsToList disable hotkeys);

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
