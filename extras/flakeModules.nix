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
      _class = "flake";
    });
    description = ''
      flake-parts "modules" for use by other flakes.

      If the flake defines only one flakeModule, it should be `flakeModules.default`.

      These are similar to standard flake-parts "modules", aside from being type "deferredModule";
      Which importantly, means they
      - are able to defer function evaluation
      - are not "evaluated eagerly"
      - are not type-checked, and merged in the same way as other module types
      - can create a new, named - top-level output, like a new `apps, programs, devshells`, etc. Such as "myLib", where
           - A: you define all of the types of any internal options
           - B: all of the merge rules for them
           - C: Can ignore the options system completely
           - D: Can export your own flake.lib functions directly under your "flakes namespace" So that others can reference it via yourflake.lib

      - To enable this, you should import `inputs.flake-parts.flakeModules.flakeModules`, 

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
