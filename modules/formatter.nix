{ config, lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  inherit (flake-parts-lib)
    mkTransposedPerSystemModule
    ;
in
mkTransposedPerSystemModule {
  name = "formatter";
  option = mkOption {
    type = types.nullOr types.package;
    default = null;
    description = ''
      A package used by <literal>nix fmt</literal>.
    '';
  };
  file = ./formatter.nix;
}
