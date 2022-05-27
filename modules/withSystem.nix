{ config, lib, flake-parts-lib, self, getSystem, ... }:
let
  inherit (lib)
    genAttrs
    mapAttrs
    mkOption
    types
    ;
  inherit (flake-parts-lib)
    mkPerSystemOption
    ;
in
{
  options = {
    perSystem = mkPerSystemOption ({ config, options, system, specialArgs, ... }: {
      _file = ./perSystem.nix;
      options = {
        allModuleArgs = mkOption {
          type = types.lazyAttrsOf (types.raw or types.unspecified);
          internal = true;
          readOnly = true;
          description = "Internal option that exposes _module.args, for use by withSystem.";
        };
      };
      config = {
        allModuleArgs = config._module.args // specialArgs // { inherit config options; };
      };
    });
  };

  config = {
    _module.args = {
      withSystem =
        system: f:
        f
          (getSystem system).allModuleArgs;
    };
  };
}
