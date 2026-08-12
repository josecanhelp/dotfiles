{
  description = "JoseCanHelp's Dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Source for ALL 47 VS Code extensions, not just the ones nixpkgs lacks.
    # nixpkgs carries 35 of them, but its pins were older than the installed
    # copies for 21, and VS Code loads the highest version it finds, so
    # declaring from nixpkgs described versions that were not running. See the
    # long comment in nix/home/darwin/vscode.nix for the full reasoning.
    #
    # Consequence: extension versions follow this input rather than the nixpkgs
    # pin, so `nix flake update` moves them.
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, home-manager
                   , nix-vscode-extensions }:
  let
    # Everything shared by every machine. Host-specific settings go in the
    # `extraModules` list of the individual host below, not in here.
    #
    # `hostname` and `user` are passed down to nix/configuration.nix as module
    # arguments, so adding a machine means adding one block below rather than
    # editing nine scattered literals. Both are required: there is no sensible
    # default for either, and a wrong guess fails in confusing ways.
    mkHost =
      { hostname
      , user
      , system ? "aarch64-darwin"
      , extraModules ? [ ]
      }:
      nix-darwin.lib.darwinSystem {
      specialArgs = { inherit hostname user; };
      modules = [
        ./nix/configuration.nix
        { nixpkgs.hostPlatform = system; }
        # Puts pkgs.vscode-marketplace in scope for nix/home/darwin/vscode.nix.
        # Darwin only: VS Code is a cask on this machine and the WSL box has no
        # GUI, so the Linux output does not need the overlay or its eval cost.
        { nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ]; }
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Off: /usr/local is already occupied by Docker, the AWS CLI, dotnet,
            # and texlive. Enabling this would chown those dirs to `user`.
            enableRosetta = false;

            # User owning the Homebrew prefix
            inherit user;

            # Automatically migrate existing Homebrew installations
            autoMigrate = true;

            # Homebrew refuses to load formulae from untrusted third-party
            # taps, which aborts `brew bundle` during activation. These are
            # the taps declared in nix/configuration.nix. nix-homebrew
            # applies trust before nix-darwin runs the bundle.
            trust.taps = [
              "shopify/shopify"
              "masaushi/tap"
            ];
          };
        }
        home-manager.darwinModules.home-manager
      ] ++ extraModules;
    };
  in
  {
    darwinConfigurations = {
      # Add a machine by adding one block here. The attribute name must match
      # the `hostname` value AND the name you pass to
      # `darwin-rebuild switch --flake .#<name>`, because nix-darwin looks
      # itself up by the machine's actual hostname.
      #
      #   "Joses-Mac-mini" = mkHost {
      #     hostname = "Joses-Mac-mini";
      #     user = "jose";
      #   };
      #
      # An Intel machine:
      #   "IntelMac" = mkHost {
      #     hostname = "IntelMac";
      #     user = "jose";
      #     system = "x86_64-darwin";
      #   };
      #
      # Host-specific tweaks go in their own module, never in the shared one:
      #   "WorkMac" = mkHost {
      #     hostname = "WorkMac";
      #     user = "jose";
      #     extraModules = [ ./nix/hosts/work.nix ];
      #   };
      "REM-JoseS-MBP1" = mkHost {
        hostname = "REM-JoseS-MBP1";
        user = "jose";
      };
    };

    # Standalone home-manager for the WSL2 box. nix-darwin cannot serve it, so
    # this is a separate output rather than another mkHost entry. Only $HOME is
    # managed there; the machine itself is not.
    homeConfigurations."jose@RockemSockem" =
      home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { user = "jose"; };
        modules = [ ./nix/home/linux ];
      };
  };
}
