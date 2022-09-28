{ config, lib, flake-parts-lib, self, ... }:
let
  inherit (lib)
    foldl'
    genAttrs
    isAttrs
    mapAttrs
    map
    attrNames
    mkOption
    types
    ;
  inherit (flake-parts-lib)
    mkPerSystemType
    ;

  rootConfig = config;

in
{
  options = {
    systems = mkOption {
      description = "All the system types to enumerate in the flake.";
      type = types.listOf types.str;
    };

    perInput = mkOption {
      description = "Function from system to function from flake to <literal>system</literal>-specific attributes.";
      type = types.functionTo (types.functionTo (types.lazyAttrsOf types.unspecified));
    };

    perSystem = mkOption {
      description = "A function from system to flake-like attributes omitting the <literal>&lt;system></literal> attribute.";
      type = mkPerSystemType ({ config, system, ... }: {
        _file = ./perSystem.nix;
        config = {
          _module.args.inputs' = mapAttrs (k: rootConfig.perInput system) self.inputs;
          _module.args.self' = rootConfig.perInput system self;
        };
      });
      apply = modules: system:
        let
          inherit (lib.evalModules {
            inherit modules;
            prefix = [ "perSystem" system ];
            specialArgs = {
              inherit system;
            };
          }) options;
        # Almost like `config`, except undefined options are filtered away.
        # This definition is incomplete, but is good enough for our purposes.
        # Limitations:
        # - Doesn't handle undefined options in submodules.
        # - Doesn't handle undefined options that have a prefix, e.g. `_module.args`.
        # TODO: Upstream a good version of this to Nixpkgs, probably as an extra result
        # from `evalModules`, e.g. `result.configFiltered`.
        #
        # The reason we do this is that we don't want to evaluate the definitions,
        # and only check whether they're defined. Hence we can't check for nullness,
        # because that will evaluate a lot of stuff unnecessarily and cause errors
        # with IFD. A more proper fix would perhaps be fixing the Nix evaluator to
        # short circuit more, specifically, in an expression like `null != { ${x} = ...; }`,
        # `x` should not be validated, since it's a set regardless.
        #
        # In general though, Nix's evaluator sucks.
        in
          foldl' (acc: k: acc // (
            let v = options.${k}; in
            if isAttrs v && v ? isDefined && v.isDefined
              then { ${k} = v.value; }
              else {}
          )) {} (attrNames options);
    };

    allSystems = mkOption {
      type = types.unspecified;
      description = "The system-specific config for each of systems.";
      internal = true;
    };
  };

  config = {
    allSystems = genAttrs config.systems config.perSystem;
    # TODO: Sub-optimal error message. Get Nix to support a memoization primop, or get Nix Flakes to support systems properly or get Nix Flakes to add a name to flakes.
    _module.args.getSystem = system: config.allSystems.${system} or (builtins.trace "using non-memoized system ${system}" config.perSystem system);
  };

}
