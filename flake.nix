{
  description = "JoseCanHelp's Dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, home-manager }:
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
  };
}
