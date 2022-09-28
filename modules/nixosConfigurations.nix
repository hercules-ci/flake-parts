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
        type = types.nullOr (types.lazyAttrsOf types.raw);
        default = null;
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
