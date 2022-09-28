{ config, lib, flake-parts-lib, ... }:
let
  inherit (lib)
    filterAttrs
    mapAttrs
    mkOption
    optionalAttrs
    types
    ;
  inherit (flake-parts-lib)
    mkSubmoduleOptions
    mkPerSystemOption
    mkIfNonEmptySet
    ;
in
{
  options = {
    flake = mkSubmoduleOptions {
      checks = mkOption {
        type = types.nullOr (types.lazyAttrsOf (types.lazyAttrsOf types.package));
        default = null;
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
          description = ''
            Derivations to be built by nix flake check.
          '';
        };
      };
    });

  };
  config = {
    flake.checks =
      mkIfNonEmptySet
        (mapAttrs
          (k: v: v.checks)
          (filterAttrs
            (k: v: v ? checks)
            config.allSystems
          ));

    perInput = system: flake:
      optionalAttrs (flake?checks.${system}) {
        checks = flake.checks.${system};
      };

  };
}
