{self, lib, flake-parts-lib, moduleLocation, ...}:

let
  inherit (lib)
    mapAttrs
    mkOption
    types
    ;
  inherit (flake-parts-lib)
    mkSubmoduleOptions
    ;
in

{
  options.flake = mkSubmoduleOptions {
    darwinModules = mkOption {
      type = types.lazyAttrsOf types.unspecified;
      default = {};
      apply = mapAttrs (k: v: { _file = "${toString moduleLocation}#darwinModules.${k}"; imports = [ v ]; });
        description = ''
          Darwin modules.

          You may use this for reusable pieces of configuration, service modules, etc for [nix-darwin](https://github.com/LnL7/nix-darwin).
        '';
    };
  };
}
