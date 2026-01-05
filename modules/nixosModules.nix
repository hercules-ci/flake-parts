{ self, lib, moduleLocation, ... }:
let
  inherit (lib)
    mapAttrs
    mkOption
    types
    ;
in
{
  options = {
    flake.nixosModules = mkOption {
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
}
