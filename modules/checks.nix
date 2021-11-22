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
      checks = mkOption {
        type = types.lazyAttrsOf (types.lazyAttrsOf types.package);
        default = { };
        description = ''
          Derivations to be built by nix flake check.
        '';
      };
    };
  };
  config = {
    flake.checks =
      mapAttrs
        (k: v: v.checks)
        (filterAttrs
          (k: v: v.checks != null)
          (genAttrs config.systems config.perSystem)
        );

    perInput = system: flake:
      optionalAttrs (flake?checks.${system}) {
        checks = flake.checks.${system};
      };

    perSystem = system: { config, ... }: {
      _file = ./checks.nix;
      options = {
        checks = mkOption {
          type = types.lazyAttrsOf types.package;
          default = { };
          description = ''
            Derivations to be built by nix flake check.
          '';
        };
      };
    };
  };
}
