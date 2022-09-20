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
    ;
in
{
  options = {
    flake = mkSubmoduleOptions {
      formatter = mkOption {
        type = types.lazyAttrsOf types.package;
        default = { };
        description = ''
          Per system package used by <literal>nix fmt</literal>.
        '';
      };
    };

    perSystem = mkPerSystemOption ({ config, ... }: {
      _file = ./formatter.nix;
      options = {
        packages = mkOption {
          type = types.nullOr types.package;
          default = null;
          description = ''
            A package used by <literal>nix fmt</literal>.
          '';
        };
      };
    });
  };
  config = {
    flake.formatter =
      mapAttrs
        (k: v: v.formatter)
        (filterAttrs
          (k: v: v.formatter != null)
          config.allSystems
        );

    perInput = system: flake:
      optionalAttrs (flake?formatter.${system}) {
        formatter = flake.formatter.${system};
      };

  };
}
