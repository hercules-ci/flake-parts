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
      devShells = mkOption {
        type = types.nullOr (types.lazyAttrsOf (types.lazyAttrsOf types.package));
        default = null;
        description = ''
          Per system an attribute set of packages used as shells.
          <literal>nix develop .#&lt;name></literal> will run <literal>devShells.&lt;system>.&lt;name></literal>.
        '';
      };
    };

    perSystem = mkPerSystemOption
      ({ config, system, ... }: {
        options = {
          devShells = mkOption {
            type = types.lazyAttrsOf types.package;
            description = ''
              An attribute set of packages to be built by <literal>nix develop .#&lt;name></literal>.
              <literal>nix build .#&lt;name></literal> will run <literal>devShells.&lt;name></literal>.
            '';
          };
        };
      });
  };
  config = {
    flake.devShells =
      mkIfNonEmptySet
        (mapAttrs
          (k: v: v.devShells)
          (filterAttrs
            (k: v: v ? devShells)
            config.allSystems
          ));

    perInput = system: flake:
      optionalAttrs (flake?devShells.${system}) {
        devShells = flake.devShells.${system};
      };
  };
}
