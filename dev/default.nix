let
  flake-parts = builtins.getFlake (toString ../.);
  lib = flake-parts.inputs.nixpkgs-lib.lib;
  sourceInfo = inputs.flake-parts.sourceInfo; # used by pre-commit module, etc
  flake = builtins.getFlake (toString ./.);
  inputs = flake.inputs // { inherit flake-parts; };
  makeResult = specialArgs: flakeModule: result:
    let
      outputs = flake.outputs // flake-parts.lib.mkFlake
        {
          inputs = inputs // { self = result; };
          # debugging tool
          specialArgs = {
            replaceSpecialArgs = newSpecialArgs:
              let
                newSpecialArgs' =
                  if lib.isFunction newSpecialArgs
                  then newSpecialArgs specialArgs
                  else newSpecialArgs;
                newResult = makeResult newSpecialArgs' flakeModule newResult;
              in
              newResult;
          } // specialArgs;
        }
        flakeModule;
    in
    outputs // sourceInfo // {
      inherit inputs outputs sourceInfo;
      _type = "flake";
    };
in
let
  # eagerly import to reproduce inline evaluation
  result = makeResult { } (import ./flake-module.nix) result;
in
result
