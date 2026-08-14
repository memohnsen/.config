{
  description = "Maddisen's Home Manager configuration";

  inputs = {
    # Keep Home Manager on the same pinned package set as the dev flakes.
    nixpkgs.url = "github:NixOS/nixpkgs/044bfe75bfe4c7bbe043dc17b5e42ea823b84a09";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    {
      homeConfigurations.maddisenmohnsen = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        modules = [ ./home.nix ];
      };
    };
}
