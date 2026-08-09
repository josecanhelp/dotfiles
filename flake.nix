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
    mkHost = { system ? "aarch64-darwin", extraModules ? [ ] }:
      nix-darwin.lib.darwinSystem {
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
            user = "jose";

            # Automatically migrate existing Homebrew installations
            autoMigrate = true;

            # Homebrew refuses to load formulae from untrusted third-party
            # taps, which aborts `brew bundle` during activation. These are
            # the taps declared in nix/configuration.nix. nix-homebrew
            # applies trust before nix-darwin runs the bundle.
            trust.taps = [
              "shopify/shopify"
              "masaushi/tap"
              "microsoft/mssql-release"
            ];
          };
        }
        home-manager.darwinModules.home-manager
      ] ++ extraModules;
    };
  in
  {
    darwinConfigurations = {
      # Add a machine by adding a line here. The attribute name must match
      # the hostname you pass to `darwin-rebuild switch --flake .#<name>`.
      #
      #   "OtherMac" = mkHost { };
      #   "IntelMac" = mkHost { system = "x86_64-darwin"; };
      #
      # Host-specific tweaks:
      #   "WorkMac" = mkHost { extraModules = [ ./nix/hosts/work.nix ]; };
      "REM-JoseS-MBP1" = mkHost { };
    };
  };
}
