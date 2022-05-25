{ lib }:
let
  inherit (lib)
    mkOption
    types
    ;

  # Polyfill functionTo to make sure it has type merging.
  # Remove 2022-12
  functionTo =
    let sample = types.functionTo lib.types.str;
    in
    if sample.functor.wrapped._type or null == "option-type"
    then types.functionTo
    else
      elemType: lib.mkOptionType {
        name = "functionTo";
        description = "function that evaluates to a(n) ${elemType.description}";
        check = lib.isFunction;
        merge = loc: defs:
          fnArgs: (lib.mergeDefinitions (loc ++ [ "[function body]" ]) elemType (map (fn: { inherit (fn) file; value = fn.value fnArgs; }) defs)).mergedValue;
        getSubOptions = prefix: elemType.getSubOptions (prefix ++ [ "[function body]" ]);
        getSubModules = elemType.getSubModules;
        substSubModules = m: functionTo (elemType.substSubModules m);
        functor = (lib.defaultFunctor "functionTo") // { type = functionTo; wrapped = elemType; };
        nestedTypes.elemType = elemType;
      };

  flake-parts-lib = {
    evalFlakeModule =
      { self
      , specialArgs ? { }
      }:
      module:

      lib.evalModules {
        specialArgs = { inherit self flake-parts-lib; inherit (self) inputs; } // specialArgs;
        modules = [ ./all-modules.nix module ];
      };

    mkFlake = args: module:
      (flake-parts-lib.evalFlakeModule args module).config.flake;

    # For extending options in an already declared submodule.
    # Workaround for https://github.com/NixOS/nixpkgs/issues/146882
    mkSubmoduleOptions =
      options:
      mkOption {
        type = types.submoduleWith {
          modules = [{ inherit options; }];
        };
      };

    mkPerSystemType =
      module:
      functionTo (types.submoduleWith {
        modules = [ module ];
        shorthandOnlyDefinesConfig = false;
      });

    mkPerSystemOption =
      module:
      mkOption {
        type = flake-parts-lib.mkPerSystemType module;
      };

  };

in
flake-parts-lib
