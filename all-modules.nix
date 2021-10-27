{ lib, ... }:
{
  imports = [
    ./modules/checks.nix
    ./modules/devShell.nix
    ./modules/legacyPackages.nix
    ./modules/packages.nix
    ./modules/perSystem.nix
  ];
}
