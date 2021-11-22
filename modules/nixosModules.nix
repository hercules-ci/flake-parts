{ config, self, lib, flake-modules-core-lib, ... }:
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
      nixosModules = mkOption {
        type = types.lazyAttrsOf types.unspecified;
        default = { };
        apply = mapAttrs (k: v: { _file = "${toString self.outPath}/flake.nix#nixosModules.${k}"; imports = [ v ]; });
        description = ''
          NixOS modules.
        '';
      };
    };
  };
}
