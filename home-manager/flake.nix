{
  description = "Maddisen's Home Manager configuration";

  inputs = {
    # Keep Home Manager on the same pinned package set as the dev flakes.
    nixpkgs.url = "github:NixOS/nixpkgs/044bfe75bfe4c7bbe043dc17b5e42ea823b84a09";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ nixpkgs, home-manager, nix-darwin, ... }:
    {
      devShells.aarch64-darwin.default = nixpkgs.legacyPackages.aarch64-darwin.mkShellNoCC {
        packages = [ nixpkgs.legacyPackages.aarch64-darwin.just ];
        shellHook = ''echo "Nix dev shell: config"'';
      };

      homeConfigurations.maddisenmohnsen = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfreePredicate = package:
            builtins.elem (nixpkgs.lib.getName package) [ "claude-code" ];
        };
        modules = [ ./home.nix ];
      };

      darwinConfigurations."Maddisens-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./darwin.nix
          home-manager.darwinModules.home-manager
          {
            # Keep the existing user profile path so GUI-launched editors and
            # shells continue to resolve the same Home Manager executables.
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = false;
            home-manager.users.maddisenmohnsen = import ./home.nix;
          }
        ];
      };
    };
}
