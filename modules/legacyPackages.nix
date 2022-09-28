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
      legacyPackages = mkOption {
        type = types.lazyAttrsOf (types.lazyAttrsOf types.raw);
        default = { };
        description = ''
          Per system, an attribute set of unmergeable values. This is also used by <literal>nix build .#&lt;attrpath></literal>.
        '';
      };
    };

    perSystem = mkPerSystemOption ({ config, ... }: {
      options = {
        legacyPackages = mkOption {
          type = types.lazyAttrsOf types.raw;
          default = { };
          description = ''
            An attribute set of unmergeable values. This is also used by <literal>nix build .#&lt;attrpath></literal>.
          '';
        };
      };
    });
  };

  config = {
    flake.legacyPackages =
      mapAttrs
        (k: v: v.legacyPackages)
        config.allSystems;

    perInput = system: flake:
      optionalAttrs (flake?legacyPackages.${system}) {
        legacyPackages = flake.legacyPackages.${system};
      };

  };
}
