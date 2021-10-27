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
in
{
  options = {
    flake = {
      legacyPackages = mkOption {
        type = types.lazyAttrsOf (types.lazyAttrsOf types.anything);
        default = { };
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
        };
      };
    };
  };
}
