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
  name = "packages";
  option = mkOption {
    type = types.lazyAttrsOf types.package;
    default = { };
    description = ''
      An attribute set of packages to be built by <literal>nix build .#&lt;name></literal>.
      <literal>nix build .#&lt;name></literal> will build <literal>packages.&lt;name></literal>.
    '';
  };
  file = ./packages.nix;
}
