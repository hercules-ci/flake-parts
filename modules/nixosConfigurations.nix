{ config, lib, flake-modules-core-lib, ... }:
let
  inherit (lib)
    mkOption
    types
    literalExpression
    ;
  inherit (flake-modules-core-lib)
    mkSubmoduleOptions
    ;
in
{
  options = {
    flake = mkSubmoduleOptions {
      nixosConfigurations = mkOption {
        type = types.lazyAttrsOf types.raw;
        default = { };
        description = ''
          Instantiated NixOS configurations.
        '';
        example = literalExpression ''
          {
            my-machine = inputs.nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = [
                ./my-machine/nixos-configuration.nix
              ];
            };
          }
        '';
      };
    };
  };
}
