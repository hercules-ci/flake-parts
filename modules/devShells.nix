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
      An attribute set of packages to be used as shells.
      [`nix develop .#<name>`](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-develop.html) will run `devShells.<name>`.
    '';
  };
  file = ./devShells.nix;
}
