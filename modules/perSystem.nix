{ config, lib, flake-parts-lib, self, ... }:
let
  inherit (lib)
    genAttrs
    mapAttrs
    mkOption
    types
    ;
  inherit (lib.strings)
    escapeNixIdentifier
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
      description = ''
        A function that pre-processes flake inputs.

        It is called for users of `perSystem` such that `inputs'.''${name} = config.perInput system inputs.''${name}`.

        This is used for [`inputs'`](../module-arguments.html#inputs) and [`self'`](../module-arguments.html#self).

        The attributes returned by the `perInput` function definitions are merged into a single namespace (per input), 
        so each module should return an attribute set with usually only one or two predictable attribute names. Otherwise,
        the `inputs'` namespace gets polluted.
      '';
      type = types.functionTo (types.functionTo (types.lazyAttrsOf types.unspecified));
    };

    perSystem = mkOption {
      description = ''
        A function from system to flake-like attributes omitting the `<system>` attribute.

        Modules defined here have access to the suboptions and [some convenient module arguments](../module-arguments.html).
      '';
      type = mkPerSystemType ({ config, system, ... }: {
        _file = ./perSystem.nix;
        config = {
          _module.args.inputs' =
            mapAttrs
              (inputName: input:
                builtins.addErrorContext "while retrieving system-dependent attributes for input ${escapeNixIdentifier inputName}" (
                  if input._type or null == "flake"
                  then rootConfig.perInput system input
                  else
                    throw "Trying to retrieve system-dependent attributes for input ${escapeNixIdentifier inputName}, but this input is not a flake. Perhaps flake = false was added to the input declarations by mistake, or you meant to use a different input, or you meant to use plain old inputs, not inputs'."
                )
              )
              self.inputs;
          _module.args.self' =
            builtins.addErrorContext "while retrieving system-dependent attributes for a flake's own outputs" (
              rootConfig.perInput system self
            );

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

    # The warning is there for a reason. Only use this in situations where the
    # performance cost has already been incurred, such as in `flakeModules.easyOverlay`,
    # where we run in the context of an overlay, and the performance cost of the
    # extra `pkgs` makes the cost of running `perSystem` probably negligible.
    _module.args.getSystemIgnoreWarning = system: config.allSystems.${system} or (config.perSystem system);
  };

}
