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
      packages = mkOption {
        type = types.lazyAttrsOf (types.lazyAttrsOf types.package);
        default = { };
        description = ''
          Per system an attribute set of packages.
          nix build .#<name> will build packages.<system>.<name>.
        '';
      };
    };
  };
  config = {
    flake.packages =
      mapAttrs
        (k: v: v.packages)
        (filterAttrs
          (k: v: v.packages != null)
          (genAttrs config.systems config.perSystem)
        );

    perInput = system: flake:
      optionalAttrs (flake?packages.${system}) {
        packages = flake.packages.${system};
      };

    perSystem = system: { config, ... }: {
      _file = ./packages.nix;
      options = {
        packages = mkOption {
          type = types.lazyAttrsOf types.package;
          default = { };
          description = ''
            An attribute set of packages to be built by nix build .#<name>.
            nix build .#<name> will build packages.<name>.
          '';
        };
      };
    };
  };
}
