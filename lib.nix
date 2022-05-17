{ lib }:
let
  inherit (lib)
    mkOption
    types
    functionTo
    ;

  flake-modules-core-lib = {
    evalFlakeModule =
      { self
      , specialArgs ? { }
      }:
      module:

      lib.evalModules {
        specialArgs = { inherit self flake-modules-core-lib; inherit (self) inputs; } // specialArgs;
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
    
    mkPerSystemType =
      module:
      types.functionTo (types.submoduleWith {
        modules = [ module ];
        shorthandOnlyDefinesConfig = false;
      });

    mkPerSystemOption =
      module:
      mkOption {
        type = flake-modules-core-lib.mkPerSystemType module;
      };

  };

in
flake-modules-core-lib
