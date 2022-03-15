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
          nix develop .#<name> will run devShells.<system>.<name>.
        '';
      };
    };
  };
  config = {
    flake.devShells =
      mapAttrs
        (k: v: v.devShells)
        (filterAttrs
          (k: v: v.devShells != null)
          config.allSystems
        );

    perInput = system: flake:
      optionalAttrs (flake?devShells.${system}) {
        devShells = flake.devShells.${system};
      };

    perSystem = system: { config, ... }: {
      _file = ./devShells.nix;
      options = {
        devShells = mkOption {
          type = types.lazyAttrsOf types.package;
          default = { };
          description = ''
            An attribute set of packages to be built by nix develop .#<name>.
            nix build .#<name> will run devShells.<name>.
          '';
        };
      };
    };
  };
}
