{ config, lib, flake-parts-lib, ... }:
let
  inherit (lib)
    filterAttrs
    mapAttrs
    mkOption
    types
    ;
  inherit (flake-parts-lib)
    mkSubmoduleOptions
    mkPerSystemOption
    ;

  packageType =
    with types;
    let
      self =
        (oneOf
          [ package
            (lazyAttrsOf self)
            (functionTo self)
          ]) // { description = "Attrs of functions or packges, with arbitrary depth."; };
    in
      lazyAttrsOf self;
in
{
  options = {
    flake = mkSubmoduleOptions {
      packages = mkOption {
        type = types.lazyAttrsOf packageType;
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
          type = packageType;
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
      filterAttrs (_: v: v != null) {
        packages = flake.packages.${system} or null;
        legacyPackages = flake.legacyPackages.${system} or null;
      };
  };
}
