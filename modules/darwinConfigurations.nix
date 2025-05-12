{ lib, flake-parts-lib, ... }:
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
      darwinConfigurations = mkOption {
        type = types.lazyAttrsOf types.raw;
        default = { };
        description = ''
          Instantiated darwin-nix configurations. Used by `darwin-rebuild`.

          `darwinConfigurations` is for specific machines.
        '';
        example = literalExpression ''
          {
            my-machine = inputs.darwin-nix.lib.darwinSystem {
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
