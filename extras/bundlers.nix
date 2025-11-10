{ lib
, flake-parts-lib
, ...
}:
let
  inherit
    (lib)
    mkOption
    types
    ;
  inherit
    (flake-parts-lib)
    mkTransposedPerSystemModule
    ;
in
mkTransposedPerSystemModule {
  name = "bundlers";
  option = mkOption {
    type = types.lazyAttrsOf (types.functionTo types.package);
    default = { };
    description = ''
      An attribute set of bundlers to be used by [`nix bundle`](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-bundle.html).

      `nix bundle --bundler .#<name>` <derivation> will bundle <derivation> using the bundler `bundlers.<name>`.
    '';
  };
  file = ./bundlers.nix;
}
