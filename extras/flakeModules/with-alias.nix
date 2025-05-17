{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  inherit (flake-parts-lib)
    mkAliasOptionModule
    ;
in
{
  imports = [ ./sans-alias.nix ];
  options.flake = mkOption {
    type = types.submoduleWith {
      modules = [
        (mkAliasOptionModule [ "flakeModule" ] [ "flakeModules" "default" ])
      ];
    };
  };
}
