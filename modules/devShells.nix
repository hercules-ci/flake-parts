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
  name = "devShells";
  option = mkOption {
    type = types.lazyAttrsOf types.package;
    default = { };
    description = ''
      An attribute set of packages to be built by <literal>nix develop .#&lt;name></literal>.
      <literal>nix build .#&lt;name></literal> will run <literal>devShells.&lt;name></literal>.
    '';
  };
  file = ./devShells.nix;
}
