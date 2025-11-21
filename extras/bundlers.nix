# Tests in: ../dev/tests/eval-tests.nix (bundlersExample)

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
      An attribute set of bundlers to be used by [`nix bundle`](https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-bundle.html).

      Bundlers are functions that accept a derivation and return a derivation.
      They package application closures into formats usable outside the Nix store.

      `nix bundle --bundler .#<name> .#<package>` bundles `<package>` using bundler `<name>`.

      Define a `default` bundler to use `nix bundle --bundler .#`.
    '';
  };
  file = ./bundlers.nix;
}
