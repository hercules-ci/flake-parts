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
  name = "legacyPackages";
  option = mkOption {
    type = types.lazyAttrsOf types.raw;
    default = { };
    description = ''
      An attribute set of unmergeable values. This is also used by <literal>nix build .#&lt;attrpath></literal>.
    '';
  };
  file = ./legacyPackages.nix;
}
