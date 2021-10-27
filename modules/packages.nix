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
      packages = mkOption {
        type = types.lazyAttrsOf (types.lazyAttrsOf types.package);
        default = { };
      };
    };
  };
  config = {
    flake.packages =
      mapAttrs
        (k: v: v.packages)
        (filterAttrs
          (k: v: v.packages != null)
          (genAttrs config.systems config.perSystem)
        );

    perInput = system: flake:
      optionalAttrs (flake?packages.${system}) {
        packages = flake.packages.${system};
      };

    perSystem = system: { config, ... }: {
      _file = ./packages.nix;
      options = {
        packages = mkOption {
          type = types.lazyAttrsOf types.package;
          default = { };
        };
      };
    };
  };
}
