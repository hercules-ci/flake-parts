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
      legacyPackages = mkOption {
        type = types.nullOr (types.lazyAttrsOf (types.lazyAttrsOf types.raw));
        default = null;
        description = ''
          Per system, an attribute set of unmergeable values. This is also used by <literal>nix build .#&lt;attrpath></literal>.
        '';
      };
    };

    perSystem = mkPerSystemOption ({ config, ... }: {
      options = {
        legacyPackages = mkOption {
          type = types.lazyAttrsOf types.raw;
          description = ''
            An attribute set of unmergeable values. This is also used by <literal>nix build .#&lt;attrpath></literal>.
          '';
        };
      };
    });
  };

  config = {
    flake.legacyPackages =
      mkIfNonEmptySet
        (mapAttrs
          (k: v: v.legacyPackages)
          (filterAttrs
            (k: v: v ? legacyPackages)
            config.allSystems
          ));

    perInput = system: flake:
      optionalAttrs (flake?legacyPackages.${system}) {
        legacyPackages = flake.legacyPackages.${system};
      };

  };
}
