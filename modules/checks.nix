{ config, lib, flake-modules-core-lib, ... }:
let
  inherit (lib)
    filterAttrs
    mapAttrs
    mkOption
    optionalAttrs
    types
    ;
  inherit (flake-modules-core-lib)
    mkSubmoduleOptions
    mkPerSystemOption
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

    perSystem = mkPerSystemOption ({ config, system, ... }: {
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
    });

  };
  config = {
    flake.checks =
      mapAttrs
        (k: v: v.checks)
        (filterAttrs
          (k: v: v.checks != null)
          config.allSystems
        );

    perInput = system: flake:
      optionalAttrs (flake?checks.${system}) {
        checks = flake.checks.${system};
      };

  };
}
