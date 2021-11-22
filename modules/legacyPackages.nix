{ config, lib, flake-modules-core-lib, ... }:
let
  inherit (lib)
    filterAttrs
    genAttrs
    mapAttrs
    mkOption
    optionalAttrs
    types
    ;
  inherit (flake-modules-core-lib)
    mkSubmoduleOptions
    ;
in
{
  options = {
    flake = mkSubmoduleOptions {
      legacyPackages = mkOption {
        type = types.lazyAttrsOf (types.lazyAttrsOf types.anything);
        default = { };
        description = ''
          Per system, an attribute set of anything. This is also used by nix build .#<attrpath>.
        '';
      };
    };
  };
  config = {
    flake.legacyPackages =
      mapAttrs
        (k: v: v.legacyPackages)
        (filterAttrs
          (k: v: v.legacyPackages != null)
          (genAttrs config.systems config.perSystem)
        );

    perInput = system: flake:
      optionalAttrs (flake?legacyPackages.${system}) {
        legacyPackages = flake.legacyPackages.${system};
      };

    perSystem = system: { config, ... }: {
      _file = ./legacyPackages.nix;
      options = {
        legacyPackages = mkOption {
          type = types.lazyAttrsOf types.anything;
          default = { };
          description = ''
            An attribute set of anything. This is also used by nix build .#<attrpath>.
          '';
        };
      };
    };
  };
}
