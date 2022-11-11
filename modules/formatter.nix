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
      A package used by [`nix fmt`](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-fmt.html).
    '';
  };
  file = ./formatter.nix;
}
