darwin_flake := "path:" + justfile_directory() + "/home-manager"
darwin_host := "Maddisens-MacBook-Pro"

# Build and activate nix-darwin and its integrated Home Manager configuration.
nix:
    sudo /run/current-system/sw/bin/darwin-rebuild switch --flake "{{darwin_flake}}#{{darwin_host}}"

# Evaluate and build the current configuration without activating it.
nix-check:
    nix flake check "{{darwin_flake}}"
    nix build "{{darwin_flake}}#darwinConfigurations.{{darwin_host}}.system" --no-link

# Refresh pinned inputs and verify the resulting system; run `just nix` to activate it.
nix-update:
    nix flake update --flake "{{justfile_directory()}}/home-manager"
    just --justfile "{{justfile_directory()}}/Justfile" nix-check

# Show system generations available for rollback.
nix-generations:
    sudo /run/current-system/sw/bin/darwin-rebuild --list-generations

# Activate the previous nix-darwin generation.
nix-rollback:
    sudo /run/current-system/sw/bin/darwin-rebuild switch --rollback
