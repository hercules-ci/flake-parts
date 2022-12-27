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

  # Stubs for self and inputs. While it'd be possible to define aliases
  # inside perSystem, that is not a general solution, and it would make
  # top.config harder to discover, stretching the learning curve rather
  # than flattening it.

  throwAliasError' = param:
    throw ''
      `${param}` (without `'`) is not a `perSystem` module argument, but a
      module argument of the top level config.

      The following is an example usage of `${param}`. Note that its binding
      is in the `top` parameter list, which is declared by the top level module
      rather than the `perSystem` module.

        top@{ config, lib, ${param}, ... }: {
          perSystem = { config, ${param}', ... }: {
            # in scope here:
            #  - ${param}
            #  - ${param}'
            #  - config (of perSystem)
            #  - top.config (note the `top@` pattern)
          };
        }
    '';

  throwAliasError = param:
    throw ''
      `${param}` is not a `perSystem` module argument, but a module argument of
      the top level config.

      The following is an example usage of `${param}`. Note that its binding
      is in the `top` parameter list, which is declared by the top level module
      rather than the `perSystem` module.

        top@{ config, lib, ${param}, ... }: {
          perSystem = { config, ... }: {
            # in scope here:
            #  - ${param}
            #  - config (of perSystem)
            #  - top.config (note the `top@` pattern)
          };
        }
    '';

in
{
  options = {
    systems = mkOption {
      description = ''
        All the system types to enumerate in the flake output subattributes.

        In other words, all valid values for `system` in e.g. `packages.<system>.foo`.
      '';
      type = types.listOf types.str;
    };

    perInput = mkOption {
      description = "Function from system to function from flake to `system`-specific attributes.";
      type = types.functionTo (types.functionTo (types.lazyAttrsOf types.unspecified));
    };

    perSystem = mkOption {
      description = "A function from system to flake-like attributes omitting the `<system>` attribute.";
      type = mkPerSystemType ({ config, system, ... }: {
        _file = ./perSystem.nix;
        config = {
          _module.args.inputs' = mapAttrs (k: rootConfig.perInput system) self.inputs;
          _module.args.self' = rootConfig.perInput system self;

          # Custom error messages
          _module.args.self = throwAliasError' "self";
          _module.args.inputs = throwAliasError' "inputs";
          _module.args.getSystem = throwAliasError "getSystem";
          _module.args.withSystem = throwAliasError "withSystem";
          _module.args.moduleWithSystem = throwAliasError "moduleWithSystem";
        };
      });
      apply = modules: system:
        (lib.evalModules {
          inherit modules;
          prefix = [ "perSystem" system ];
          specialArgs = {
            inherit system;
          };
        }).config;
    };

    allSystems = mkOption {
      type = types.lazyAttrsOf types.unspecified;
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
