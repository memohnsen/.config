# Build and activate nix-darwin and its integrated Home Manager configuration.
nix:
    system_path="$(nix build ./home-manager#darwinConfigurations.Maddisens-MacBook-Pro.system --no-link --print-out-paths)" && sudo "$system_path/activate"
