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
    mkAliasOptionModule
    ;

  flakeModulesOption = mkOption {
    type = types.lazyAttrsOf types.deferredModule;
    default = { };
    apply = mapAttrs (k: v: {
      _file = "${toString self.outPath}/flake.nix#flakeModules.${k}";
      key = "${toString self.outPath}/flake.nix#flakeModules.${k}";
      imports = [ v ];
    });
    description = ''
      flake-parts modules for use by other flakes.

      If the flake defines only one module, it should be flakeModules.default.

      You can not use this option in defining the flake's own `imports`. Instead, you can
      put the module in question into its own file and reference it both in `imports` and
      export it with this option.
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
