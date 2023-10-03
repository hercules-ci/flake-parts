#
# Nixpkgs module. The only exception to the rule.
#
# Provides customizable `nixpkgs` and `pkgs` arguments in `perSystem`.
#
# Arguably, this shouldn't be in flake-parts, but in nixpkgs.
# Nixpkgs could define its own module that does this, which would be
# a more consistent UX, but for now this will do.
#
# The existence of this module does not mean that other flakes' logic
# will be accepted into flake-parts, because it's against the
# spirit of Flakes.
#
{ config, flake-parts-lib, inputs, lib, options, ... }:
let
  inherit (lib)
    last
    literalExpression
    mapAttrs
    mdDoc
    mkDefault
    mkOption
    mkOptionDefault
    mkOverride
    toList
    types
    ;
  inherit (flake-parts-lib)
    mkPerSystemOption
    mkSubmoduleOptions
    ;
  extendSubModules = type: modules:
    type.substSubModules (type.getSubModules ++ modules);
  getOptionSubOptions = locSuffix: opt:
    let
      loc = opt.loc ++ locSuffix;
      type = extendSubModules opt.type [{ _module.args.name = last loc; }];
    in
    type.getSubOptions loc;
  mkSubmoduleOptionsWithShorthand =
    options: mkOption {
      type = types.submoduleWith {
        modules = [{ inherit options; }];
        shorthandOnlyDefinesConfig = true;
      };
    };
  # Shorthand for `types.submoduleWith`.
  submoduleWithModules =
    { ... }@attrs:
    modules:
    types.submoduleWith (attrs // { modules = toList modules; });
  rootConfig = config;
  rootOptions = options;
in
{
  options = {
    nixpkgs = {
      evals = mkOption {
        default = { default = { }; };
        description = ''
          Configuration for Nixpkgs evaluations of {option}`perSystem.nixpkgs.evals`.
        '';
        type = types.lazyAttrsOf (submoduleWithModules { } ({ config, name, options, ... }: {
          _file = ./nixpkgs.nix;
          options = {
            input = mkOption {
              description = mdDoc ''
                Nixpkgs function for evaluation.
              '';
              default = inputs.nixpkgs or (throw
                "flake-parts: The flake does not have a `nixpkgs` input. Please add it, or set `${options.input}` yourself."
              );
              defaultText = literalExpression ''inputs.nixpkgs'';
              type = types.coercedTo types.path import (types.functionTo types.unspecified);
            };
            settings = mkOption {
              default = { };
              description = mdDoc ''
                Settings argument for the Nixpkgs evaluations of {option}`perSystem.nixpkgs.evals.<name>`.
              '';
              type = rootOptions.nixpkgs.settings.type;
            };
          };
          config = {
            settings = mkDefault rootConfig.nixpkgs.settings;
          };
        }));
      };
      settings = mkOption {
        default = { };
        description = mdDoc ''
          Default settings argument for each Nixpkgs evaluations of {option}`nixpkgs.evals`.
        '';
        # This submodule uses `shorthandOnlyDefinesConfig` because of the top-level `config`
        # attribute and to make future upstreaming of this module to Nixpkgs easier.
        type = submoduleWithModules { shorthandOnlyDefinesConfig = true; } ({ config, name, options, ... }: {
          _file = ./nixpkgs.nix;
          freeformType = types.lazyAttrsOf types.raw;
          options = {
            config = mkOption {
              default = { };
              description = mdDoc ''
                Config for this Nixpkgs evaluation.
              '';
              type = submoduleWithModules { } {
                _file = ./nixpkgs.nix;
                freeformType = types.lazyAttrsOf types.raw;
              };
            };
            crossOverlays = mkOption {
              default = [ ];
              description = mdDoc ''
                List of Nixpkgs overlays to apply to target packages only for this Nixpkgs evaluation.
              '';
              type = types.listOf (types.uniq (types.functionTo (types.functionTo (types.lazyAttrsOf types.unspecified))));
            };
            overlays = mkOption {
              default = [ ];
              description = mdDoc ''
                List of Nixpkgs overlays for this Nixpkgs evaluation.
              '';
              type = types.listOf (types.uniq (types.functionTo (types.functionTo (types.lazyAttrsOf types.unspecified))));
            };
          };
        });
      };
    };
    perSystem = mkPerSystemOption ({ config, system, ... }: {
      _file = ./nixpkgs.nix;
      options = {
        nixpkgs = {
          evals = mkOption {
            default = { };
            description = ''
              Configuration for Nixpkgs evaluations.
            '';
            type = types.lazyAttrsOf (submoduleWithModules { } [
              ({ config, name, options, ... }: {
                _file = ./nixpkgs.nix;
                options = {
                  output = mkOption {
                    default = rootConfig.nixpkgs.evals.${name}.input config.settings;
                    defaultText = literalExpression
                      ''config.nixpkgs.evals.''${name}.input config.perSystem.nixpkgs.''${name}.settings'';
                    description = mdDoc ''
                      Evaluated Nixpkgs.
                    '';
                    type = types.raw;
                  };
                  settings = mkOption {
                    default = { };
                    description = mdDoc ''
                      Settings argument for the Nixpkgs evaluations of {option}`perSystem.nixpkgs.evals.<name>`.
                    '';
                    type = (getOptionSubOptions [ name ] rootOptions.nixpkgs.evals).settings.type;
                  };
                };
                config = {
                  settings = mkDefault rootConfig.nixpkgs.evals.${name}.settings;
                };
              })
              # Separate module, for type merging 
              ({ config, name, options, ... }: {
                _file = ./nixpkgs.nix;
                options = {
                  # `mkSubmoduleOptions` can't be used here due to `shorthandOnlyDefinesConfig`.
                  settings = mkSubmoduleOptionsWithShorthand {
                    localSystem = mkOption {
                      apply = lib.systems.elaborate;
                      default = config.settings.crossSystem;
                      defaultText = literalExpression ''config.perSystem.nixpkgs.evals.''${name}.crossSystem'';
                      description = mdDoc ''
                        Specifies the platform on which Nixpkgs packages should be built.
                        Also known as `buildPlatform`.
                        By default, Nixpkgs packages are built on the system where they run, but
                        you can change where it's built. Setting this option will cause NixOS to
                        be cross-compiled.

                        For instance, if you're doing distributed multi-platform deployment,
                        or if you're building for machines, you can set this to match your
                        development system and/or build farm.
                      '';
                      type = types.either types.str types.attrs;
                    };
                    crossSystem = mkOption {
                      apply = lib.systems.elaborate;
                      default = system;
                      defaultText = literalExpression ''system'';
                      description = mdDoc ''
                        Specifies the system where packages from this Nixpkgs evaluation will run.
                        Also known as `hostPlatform`.

                        To cross-compile, see also {option}`config.perSystem.nixpkgs.evals.<name>.localSystem`.
                      '';
                      type = types.either types.str types.attrs;
                    };
                  };
                };
              })
            ]);
          };
        };
      };
      config = {
        nixpkgs = {
          evals = mapAttrs (name: genericConfig: { }) rootConfig.nixpkgs.evals;
        };
      };
    });
  };
  config = {
    perSystem = { config, nixpkgs, options, ... }: {
      _file = ./nixpkgs.nix;
      config = {
        _module.args.nixpkgs = mkOptionDefault (mapAttrs (name: nixpkgs: nixpkgs.output) config.nixpkgs.evals);
        _module.args.pkgs = mkOptionDefault (
          nixpkgs.default or (throw "flake-parts: The `perSystem` argument `nixpkgs` does not have a default attribute. Please configure `${options._module.args}.nixpkgs.default`, or set `${options._module.args}.nixpkgs` or `${options._module.args}.pkgs` yourself.")
        );
      };
    };
  };
}
