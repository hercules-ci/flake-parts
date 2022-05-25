{ lib, ... }:
{
  imports = [
    ./modules/apps.nix
    ./modules/checks.nix
    ./modules/darwinModules.nix
    ./modules/devShells.nix
    ./modules/flake.nix
    ./modules/legacyPackages.nix
    ./modules/nixosConfigurations.nix
    ./modules/nixosModules.nix
    ./modules/nixpkgs.nix
    ./modules/overlays.nix
    ./modules/packages.nix
    ./modules/perSystem.nix
  ];
}
