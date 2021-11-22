{ lib, ... }:
{
  imports = [
    ./modules/checks.nix
    ./modules/darwinModules.nix
    ./modules/devShell.nix
    ./modules/flake.nix
    ./modules/legacyPackages.nix
    ./modules/packages.nix
    ./modules/perSystem.nix
  ];
}
