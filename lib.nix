{ lib }:
let
  inherit (lib)
    mkOption
    mkOptionType
    defaultFunctor
    isAttrs
    isFunction
    showOption
    throwIf
    types
    warnIf
    ;
  inherit (lib.types)
    path
    submoduleWith
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

  # Polyfill https://github.com/NixOS/nixpkgs/pull/163617
  deferredModuleWith = lib.deferredModuleWith or (
    attrs@{ staticModules ? [ ] }: mkOptionType {
      name = "deferredModule";
      description = "module";
      check = x: isAttrs x || isFunction x || path.check x;
      merge = loc: defs: staticModules ++ map (def: lib.setDefaultModuleLocation "${def.file}, via option ${showOption loc}" def.value) defs;
      inherit (submoduleWith { modules = staticModules; })
        getSubOptions
        getSubModules;
      substSubModules = m: deferredModuleWith (attrs // {
        staticModules = m;
      });
      functor = defaultFunctor "deferredModuleWith" // {
        type = deferredModuleWith;
        payload = {
          inherit staticModules;
        };
        binOp = lhs: rhs: {
          staticModules = lhs.staticModules ++ rhs.staticModules;
        };
      };
    }
  );

  errorExample = ''
    For example:

        outputs = inputs@{ flake-parts, ... }:
          flake-parts.lib.mkFlake { inherit inputs; } { /* module */ };

    To avoid an infinite recursion, *DO NOT* pass `self.inputs` and
    *DO NOT* pass `inherit (self) inputs`, but pass the output function
    arguments as `inputs` like above.
  '';

  flake-parts-lib = {
    evalFlakeModule =
      args@
      { inputs ? self.inputs
      , specialArgs ? { }

        # legacy
      , self ? inputs.self or (throw ''
          When invoking flake-parts, you must pass all the flake output arguments,
          and not just `self.inputs`.

          ${errorExample}
        '')
      }:
      throwIf
        (!args?self && !args?inputs) ''
        When invoking flake-parts, you must pass in the flake output arguments.

        ${errorExample}
      ''
        warnIf
        (!args?inputs) ''
        When invoking flake-parts, it is recommended to pass all the flake output
        arguments in the `inputs` parameter. If you only pass `self`, it's not
        possible to use the `inputs` module argument in the module `imports`.

        Please pass the output function arguments. ${errorExample}
      ''

        (module:
        lib.evalModules {
          specialArgs = {
            inherit self flake-parts-lib;
            inputs = args.inputs or /* legacy, warned above */ self.inputs;
          } // specialArgs;
          modules = [ ./all-modules.nix module ];
        }
        );

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
      deferredModuleWith {
        staticModules = [ module ];
      };

    mkPerSystemOption =
      module:
      mkOption {
        type = flake-parts-lib.mkPerSystemType module;
      };

    # Helper function for defining a per-system option that
    # gets transposed by the usual flake system logic to a
    # top-level flake attribute.
    mkTransposedPerSystemModule = { name, option, file }: {
      _file = file;

      options = {
        flake = flake-parts-lib.mkSubmoduleOptions {
          ${name} = mkOption {
            type = types.lazyAttrsOf option.type;
            default = { };
            description = ''
              See {option}`perSystem.${name}` for description and examples.
            '';
          };
        };

        perSystem = flake-parts-lib.mkPerSystemOption {
          _file = file;

          options.${name} = option;
        };
      };

      config = {
        transposition.${name} = { };
      };
    };
  };

in
flake-parts-lib
