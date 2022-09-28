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
      formatter = mkOption {
        type = types.nullOr (types.lazyAttrsOf types.package);
        default = null;
        description = ''
          Per system package used by <literal>nix fmt</literal>.
        '';
      };
    };

    perSystem = mkPerSystemOption ({ config, ... }: {
      _file = ./formatter.nix;
      options = {
        formatter = mkOption {
          type = types.package;
          description = ''
            A package used by <literal>nix fmt</literal>.
          '';
        };
      };
    });
  };
  config = {
    flake.formatter =
      mkIfNonEmptySet
        (mapAttrs
          (k: v: v.formatter)
          (filterAttrs
            (k: v: v ? formatter)
            config.allSystems
          ));

    perInput = system: flake:
      optionalAttrs (flake?formatter.${system}) {
        formatter = flake.formatter.${system};
      };

  };
}
