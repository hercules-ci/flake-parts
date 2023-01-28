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
    getAttrFromPath
    setAttrByPath
    attrByPath
    optionalAttrs
    ;
  inherit (lib.modules)
    mkAliasAndWrapDefsWithPriority;
  inherit (lib.types)
    path
    submoduleWith
    ;

  # Polyfill isFlake until Nix with https://github.com/NixOS/nix/pull/7207 is common
  isFlake = maybeFlake:
    if maybeFlake ? _type
    then maybeFlake._type == "flake"
    else maybeFlake ? inputs && maybeFlake ? outputs && maybeFlake ? sourceInfo;

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

  # Use a list of lib overlays to extend a lib
  mkExtendedLib = (
    let libExtend = lib: lib.extend;
    in overlays: lib: builtins.foldl' libExtend lib overlays
  );

  # The overlays we are passed could be any of:
  #
  # (1) A simple attribute attribute set
  # (2) A function from `prev` to an attribute set
  # (3) A function from `final` and `prev` to an attribute set
  # (4) A function from `inputs`, `final`, `prev`, to an attribute set
  # (5) A path or string pointing at a file containing any of (1) - (4)
  #
  # We seek to normalize these possibilities so that we always have a function
  # from `final` and `prev` to an attribute set, which is suitable for use with
  # mkExtendedLib. This may mean specializing on the `inputs` that we are passed.
  #
  toStandardOverlay = inputs: freeformOverlay: (
    let
      reifiedFreeformOverlay = (
        if (builtins.isPath freeformOverlay) || (builtins.isString freeformOverlay)
        then import freeformOverlay
        else freeformOverlay
      );
    in (final: prev:
      # apply the correct number of arguments to `reifiedFreeformOverlay`. Of note
      # is the fact that the bindings that pass too many args should not blow up
      # because laziness and short-circuiting should ensure that they are never
      # actually invoked.
      let
        noArg = reifiedFreeformOverlay;
        oneArg = reifiedFreeformOverlay prev;
        twoArg = reifiedFreeformOverlay final prev;
        threeArg = reifiedFreeformOverlay inputs final prev;
      in
        if ! builtins.isFunction noArg then noArg
        else if ! builtins.isFunction oneArg then oneArg
        else if ! builtins.isFunction twoArg then twoArg
        else if ! builtins.isFunction threeArg then threeArg
        else throw ''
          Received a lib overlay that takes the wrong number of args. Please ensure
          that your lib overlay function takes some suffix of this potential argument
          list: `inputs`, `final`, `prev`
        ''
    )
  );

  # Convert a list or attribute set of freeform overlays to a list of standard
  # overlays, suitable for use with `mkExtendedLib`
  getOverlayList = inputOverlays: (
    if builtins.isList inputOverlays
    then inputs: builtins.map (toStandardOverlay inputs) inputOverlays
    else getOverlayList (builtins.attrValues inputOverlays)
  );

  flake-parts-lib = {

    inherit mkExtendedLib;

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
      , libOverlays ? [ ]
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
          let fullLib = mkExtendedLib (getOverlayList libOverlays inputs) lib;
          in fullLib.evalModules {
          specialArgs = {
            inherit self flake-parts-lib;
            inputs = args.inputs or /* legacy, warned above */ self.inputs;
          } // specialArgs;
          modules = [ ./all-modules.nix module ];
        }
        );

    # Function to extract the default flakeModule from
    # what may be a flake, returning the argument unmodified
    # if it's not a flake.
    #
    # Useful to map over an 'imports' list to make it less
    # verbose in the common case.
    defaultModule = maybeFlake:
      if isFlake maybeFlake
      then maybeFlake.flakeModules.default or maybeFlake
      else maybeFlake;

    mkFlake = args: module:
      let
        loc =
          if args?inputs.self.outPath
          then args.inputs.self.outPath + "/flake.nix"
          else "<mkFlake argument>";
        mod = lib.setDefaultModuleLocation loc module;
        eval = flake-parts-lib.evalFlakeModule args mod;
      in
      eval.config.flake;

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

    # Needed pending https://github.com/NixOS/nixpkgs/pull/198450
    mkAliasOptionModule = from: to: { config, options, ... }:
      let
        fromOpt = getAttrFromPath from options;
        toOf = attrByPath to
          (abort "Renaming error: option `${showOption to}' does not exist.");
        toType = let opt = attrByPath to { } options; in opt.type or (types.submodule { });
      in
      {
        options = setAttrByPath from (mkOption
          {
            visible = true;
            description = lib.mdDoc "Alias of {option}`${showOption to}`.";
            apply = x: (toOf config);
          } // optionalAttrs (toType != null) {
          type = toType;
        });
        config = (mkAliasAndWrapDefsWithPriority (setAttrByPath to) fromOpt);
      };
  };

in
flake-parts-lib
