{ self, lib, flake-parts-lib, moduleLocation, ... }:
let
  inherit (lib)
    mapAttrs
    mkOption
    types
    ;
  inherit (flake-parts-lib)
    mkAliasOptionModule
    ;

  flakeModulesOption = mkOption {
    type = types.lazyAttrsOf types.deferredModule;
    default = { };
    apply = mapAttrs (k: v: {
      _file = "${toString moduleLocation}#flakeModules.${k}";
      key = "${toString moduleLocation}#flakeModules.${k}";
      imports = [ v ];
    });
    description = ''
      flake-parts modules for use by other flakes.

      If the flake defines only one module, it should be `flakeModules.default`.

      You can not read this option in defining the flake's own `imports`. Instead, you can
      put the module in question into its own file or let binding and reference
      it both in `imports` and export it with this option.

      See [Dogfood a Reusable Module](../dogfood-a-reusable-module.md) for details and an example.
    '';
  };
in
{
  options = {
    flake = mkOption {
      type = types.submoduleWith {
        modules = [
          (mkAliasOptionModule [ "flakeModule" ] [ "flakeModules" "default" ])
          {
            options.flakeModules = flakeModulesOption;
          }
        ];
      };
    };
  };
}
