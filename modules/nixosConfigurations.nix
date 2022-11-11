{ config, lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkOption
    types
    literalExpression
    ;
  inherit (flake-parts-lib)
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
          Instantiated NixOS configurations. Used by `nixos-rebuild`.
        '';
        example = literalExpression ''
          {
            my-machine = inputs.nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = [
                ./my-machine/nixos-configuration.nix
                config.nixosModules.my-module
              ];
            };
          }
        '';
      };
    };
  };
}
