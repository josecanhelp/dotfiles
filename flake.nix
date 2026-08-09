{
  description = "JoseCanHelp's Dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }: {
    darwinConfigurations."REM-JoseS-MBP1" = nix-darwin.lib.darwinSystem {
      modules = [
        ./nix/configuration.nix
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
          };
        }
      ];
    };
  };
}
