{ self, lib, flake-parts-lib, moduleLocation, ... }:
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
  options = {
    flake = mkSubmoduleOptions {
      nixosModules = mkOption {
        type = types.lazyAttrsOf types.deferredModule;
        default = { };
        apply = mapAttrs (k: v: { 
          _class = "nixos";
          _file = "${toString moduleLocation}#nixosModules.${k}"; 
          imports = [ v ]; 
        });
        description = ''
          NixOS modules.

          You may use this for reusable pieces of configuration, service modules, etc.
        '';
      };
    };
  };
}
