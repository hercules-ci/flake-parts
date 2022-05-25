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
      packages = mkOption {
        type = types.lazyAttrsOf (types.lazyAttrsOf types.package);
        default = { };
        description = ''
          Per system an attribute set of packages.
          <literal>nix build .#&lt;name></literal> will build <literal>packages.&lt;system>.&lt;name></literal>.
        '';
      };
    };

    perSystem = mkPerSystemOption ({ config, ... }: {
      _file = ./packages.nix;
      options = {
        packages = mkOption {
          type = types.lazyAttrsOf types.package;
          default = { };
          description = ''
            An attribute set of packages to be built by <literal>nix build .#&lt;name></literal>.
            <literal>nix build .#&lt;name></literal> will build <literal>packages.&lt;name></literal>.
          '';
        };
      };
    });
  };
  config = {
    flake.packages =
      mapAttrs
        (k: v: v.packages)
        (filterAttrs
          (k: v: v.packages != null)
          config.allSystems
        );

    perInput = system: flake:
      optionalAttrs (flake?packages.${system}) {
        packages = flake.packages.${system};
      };

  };
}
