{ lib }:
let
  inherit (lib)
    mkOption
    types
    ;

  flake-modules-core-lib = {
    evalFlakeModule =
      { self
      , specialArgs ? { }
      }:
      module:

      lib.evalModules {
        specialArgs = { inherit self flake-modules-core-lib; } // specialArgs;
        modules = [ ./all-modules.nix module ];
      };
  };
in
flake-modules-core-lib
