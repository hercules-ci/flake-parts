{ config, lib, flake-parts-lib, self, ... }:
let
  inherit (lib)
    genAttrs
    mapAttrs
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
    };

    allSystems = mkOption {
      type = types.lazyAttrsOf types.unspecified;
      description = "The system-specific config for each of systems.";
      internal = true;
    };
  };

  config = {
    perSystem = system: { _module.args.system = system; };
    allSystems = genAttrs config.systems config.perSystem;
    # TODO: Sub-optimal error message. Get Nix to support a memoization primop, or get Nix Flakes to support systems properly or get Nix Flakes to add a name to flakes.
    _module.args.getSystem = system: config.allSystems.${system} or (builtins.trace "using non-memoized system ${system}" config.perSystem system);
  };

}
