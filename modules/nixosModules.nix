{ config, self, lib, flake-parts-lib, ... }:
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
    ;
in
{
  options = {
    flake = mkSubmoduleOptions {
      nixosModules = mkOption {
        type = types.nullOr (types.lazyAttrsOf types.unspecified);
        default = null;
        apply = x: if x == null
          then null
          else mapAttrs (k: v: { _file = "${toString self.outPath}/flake.nix#nixosModules.${k}"; imports = [ v ]; }) x;
        description = ''
          NixOS modules.
        '';
      };
    };
  };
}
