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
      devShells = mkOption {
        type = types.lazyAttrsOf (types.lazyAttrsOf types.package);
        default = { };
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
            default = { };
            description = ''
              An attribute set of packages to be built by <literal>nix develop .#&lt;name></literal>.
              <literal>nix build .#&lt;name></literal> will run <literal>devShells.&lt;name></literal>.
            '';
          };
        };
      });
  };
  config = {
    transposition.devShells = { };
  };
}
