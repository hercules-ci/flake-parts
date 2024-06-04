{ lib, moduleLocation, ... }:
let
  inherit (lib)
    mapAttrs
    mkOption
    types
    ;
  inherit (lib.strings)
    escapeNixIdentifier
    ;

  addInfo = class: moduleName:
    if class == "generic"
    then module: module
    else
      module:
      # TODO: set key?
      {
        _class = class;
        _file = "${toString moduleLocation}#modules.${escapeNixIdentifier class}.${escapeNixIdentifier moduleName}";
        imports = [ module ];
      };
in
{
  options = {
    flake.modules = mkOption {
      type = types.lazyAttrsOf (types.lazyAttrsOf types.deferredModule);
      description = ''
        Groups of modules published by the flake.

        The outer attributes declare the [`class`](https://nixos.org/manual/nixpkgs/stable/#module-system-lib-evalModules-param-class) of the modules within it.
        The special attribute `generic` does not declare a class, allowing its modules to be used in any module class.
      '';
      # TODO: Add one or two real-world examples.
      example = lib.literalExpression ''
        {
          flake-parts = {
            foo = … some module …;
          };
          generic = {
            my-pkgs = { _module.args.my-pkgs = …; };
          };
        }
      '';
      apply = mapAttrs (k: mapAttrs (addInfo k));
    };
  };
}
