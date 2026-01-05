{ lib
  # Optionally a string with extra version info to be included in the error message
  # in case is lib is out of date. Empty or starts with space.
, revInfo ? ""
}:
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

  /**
    Deprecated for any use except type-merging into `perSystem`.
    Use `lib.types.deferredModuleWith` instead, and add `apply = m: [ m ];` if needed.

    The deferredModule type was pioneered in flake-parts for the `perSystem` option.
    The Nixpkgs version has an improved merge function that returns a single module,
    whereas this version returns a list. The flake-parts version was not updated to
    match this improvement in Nixpkgs.

    # History

    This predates `lib.types.deferredModuleWith`, added in Nixpkgs 22.11
    (https://github.com/NixOS/nixpkgs/pull/163617).
    Documented as deprecated in flake-parts in January 2026.
  */
  deferredModuleWith =
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
    };

  # Internal: preserves legacy list-merge behavior for perSystem type-merging.
  mkLegacyDeferredModuleType =
    module:
    deferredModuleWith {
      staticModules = [ module ];
    };

  errorExample = ''
    For example:

        outputs = inputs@{ flake-parts, ... }:
          flake-parts.lib.mkFlake { inherit inputs; } { /* module */ };

    To avoid an infinite recursion, *DO NOT* pass `self.inputs` and
    *DO NOT* pass `inherit (self) inputs`, but pass the output function
    arguments as `inputs` like above.
  '';

  flake-parts-lib = rec {
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
      , moduleLocation ? "${self.outPath}/flake.nix"
      }:
      let
        inputsPos = builtins.unsafeGetAttrPos "inputs" args;
        errorLocation =
          # Best case: user makes it explicit
          args.moduleLocation or (
            # Slightly worse: Nix does not technically commit to unsafeGetAttrPos semantics
            if inputsPos != null
            then inputsPos.file
            # Slightly worse: self may not be valid when an error occurs
            else if args?inputs.self.outPath
            then args.inputs.self.outPath + "/flake.nix"
            # Fallback
            else "<mkFlake argument>"
          );
      in
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
            inherit self flake-parts-lib moduleLocation;
            inputs = args.inputs or /* legacy, warned above */ self.inputs;
          } // specialArgs;
          modules = [ ./all-modules.nix (lib.setDefaultModuleLocation errorLocation module) ];
          class = "flake";
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
        eval = flake-parts-lib.evalFlakeModule args module;
      in
      eval.config.flake;

    /**
      Deprecated. Declare options directly, e.g. `options.foo.bar = mkOption { ... }`,
      provided that `foo` is already declared as a submodule option.

      In flake-parts, `flake` is declared as a submodule option by the core modules,
      so `options.flake.<name>` declarations work directly.

      This function wraps option declarations in a submodule, allowing them to
      be merged into an existing submodule option. For example, if `foo` is
      already declared as a submodule option, using
      `options.foo = mkSubmoduleOptions { bar = mkOption {...}; }` would add
      `bar` to the `foo` submodule.

      # History

      This was a workaround for https://github.com/NixOS/nixpkgs/issues/146882,
      fixed in Nixpkgs 22.05 by https://github.com/NixOS/nixpkgs/pull/156533.
      With the fix, declaring `options.foo.bar` directly works when `foo` is
      already a submodule option. Documented as deprecated in flake-parts in January 2026.
    */
    mkSubmoduleOptions =
      options:
      mkOption {
        type = types.submoduleWith {
          modules = [{ inherit options; }];
        };
      };

    /**
      Deprecated. Use mkPerSystemType/mkPerSystemOption for `perSystem` type-merging, or
      use Nixpkgs `types.deferredModule` directly, noting the lack of list wrapping;
      see `deferredModuleWith` docs.
    */
    mkDeferredModuleType = mkLegacyDeferredModuleType;

    /**
      Given a module, construct an option type suitable for type-merging into `perSystem`'s type.
    */
    mkPerSystemType = mkLegacyDeferredModuleType;

    /**
      Deprecated. Use mkPerSystemOption for `perSystem` type-merging, or
      use `mkOption` and Nixpkgs `types.deferredModule` directly, noting the
      lack of list wrapping; see `deferredModuleWith` docs.
    */
    mkDeferredModuleOption =
      module:
      mkOption {
        type = flake-parts-lib.mkPerSystemType module;
      };

    /**
      Given a module, construct an option declaration suitable for merging into the core `perSystem` module.
    */
    mkPerSystemOption = mkDeferredModuleOption;

    # Polyfill https://github.com/NixOS/nixpkgs/pull/344216
    # Nixpkgs master 2024-12-09, Nixpkgs 25.05
    attrsWith = types.attrsWith or ({ elemType, lazy ? false, placeholder ? "name" }:
      if lazy then types.attrsOf elemType else types.lazyAttrsOf elemType);

    # Helper function for defining a per-system option that
    # gets transposed by the usual flake system logic to a
    # top-level flake attribute.
    mkTransposedPerSystemModule = { name, option, file }: {
      _file = file;

      options = {
        flake.${name} = mkOption {
          type = attrsWith {
            elemType = option.type;
            lazy = true;
            placeholder = "system";
          };
          default = { };
          description = ''
            See {option}`perSystem.${name}` for description and examples.
          '';
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
            description = "Alias of {option}`${showOption to}`.";
            apply = x: (toOf config);
          } // optionalAttrs (toType != null) {
          type = toType;
        });
        config = mkAliasAndWrapDefsWithPriority (setAttrByPath to) fromOpt;
      };

    # Helper function for importing while preserving module location. To be added
    # in nixpkgs: https://github.com/NixOS/nixpkgs/pull/230588
    # I expect these functions to remain identical. This one will stick around
    # for a while to support older nixpkgs-lib.
    importApply =
      modulePath: staticArgs:
      lib.setDefaultModuleLocation modulePath (import modulePath staticArgs);

    inherit (import ./lib/memoize/memoize.nix {
      inherit lib;
    }) memoizeStr;

    /**
      `importAndPublish name module` returns a module that both imports the `module`, and exposes it as flake attribute `modules.flake.${name}`.

      This also imports the optional [`modules`](https://flake.parts/options/flake-parts-modules.html) module to support that.
    */
    importAndPublish = name: module: { lib, ... }: {
      _class = "flake";
      imports = [
        module
        ./extras/modules.nix
      ];
      flake.modules.flake.${name} = module;
    };
  };

  # A best effort, lenient estimate. Please use a recent nixpkgs lib if you
  # override it at all.
  minVersion = "23.05pre-git";

in

if builtins.compareVersions lib.version minVersion < 0
then
  abort ''
    The nixpkgs-lib dependency of flake-parts was overridden but is too old.
    The minimum supported version of nixpkgs-lib is ${minVersion},
    but the actual version is ${lib.version}${revInfo}.
  ''
else

  flake-parts-lib
