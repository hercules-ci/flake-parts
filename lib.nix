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

    # For extending options in an already declared submodule.
    # Workaround for https://github.com/NixOS/nixpkgs/issues/146882
    mkSubmoduleOptions =
      options:
      mkOption {
        type = types.submoduleWith {
          modules = [ { inherit options; } ];
        };
      };
  };

in
flake-modules-core-lib
