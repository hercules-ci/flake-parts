{ lib, config, inputs, extendModules, partitionStack, self, ... }:
let
  inherit (lib)
    literalMD
    mapAttrs
    mkOption
    optionalAttrs
    types
    ;

  partitionModule = { config, options, name, ... }: {
    options = {
      extraInputsFlake = mkOption {
        type = types.raw;
        description = ''
          Location of a flake whose inputs to add to the inputs module argument in the partition.
          Note that flake `follows` are resolved without any awareness of inputs that are not in the flake.
          As a consequence, a `follows` entry in the flake inputs can not refer to inputs that are not in that specific flake.

          Implementation note: if the type of `extraInputsFlake` is a path, it is loaded with an expression-based reimplementation of `builtins.getFlake`, as `getFlake` is incapable of loading paths in pure mode as of writing.
        '';
        example = lib.literalExpression "./dev";
      };
      extraInputs = mkOption {
        type = types.lazyAttrsOf types.raw;
        description = ''
          Extra inputs to add to the inputs module argument in the partition.

          This can be used as a workaround for the fact that transitive inputs are locked in the "end user" flake.
          That's not desirable for inputs they don't need, such as development inputs.
        '';
        default = { };
        defaultText = literalMD ''
          if `extraInputsFlake` is set, then `builtins.getFlake extraInputsFlake`, else `{ }`
        '';
      };
      module = mkOption {
        type = (extendModules {
          specialArgs =
            let
              inputs2 = inputs // config.extraInputs // {
                self = self2;
              };
              self2 = self // {
                inputs = inputs2;
              };
            in
            {
              inputs = inputs2;
              self = self2;
              partitionStack = partitionStack ++ [ name ];
            };
        }).type;
        default = { };
        description = ''
          A re-evaluation of the flake-parts top level modules.

          You may define config definitions, `imports`, etc here, and it can be read like any other submodule.
        '';
        example = lib.literalExpression ''
          {
            imports = [
              ./dev/flake-module.nix
            ];
          }
        '';
        visible = "shallow";
      };
    };
    config = {
      extraInputs = lib.mkIf options.extraInputsFlake.isDefined (
        let
          p = options.extraInputsFlake.value;
          flake =
            if builtins.typeOf p == "path"
            then get-flake p
            else builtins.getFlake p;
        in
        flake.inputs
      );
    };
  };

  # Nix does not recognize that a flake like "${./dev}", which is a content
  # addressed store path is a pure input, so we have to fetch and wire it
  # manually with flake-compat.
  get-flake = src: (flake-compat { inherit src; system = throw "operating flake-compat in pure mode; system not allowed to be used"; }).outputs;
  # TODO: update
  flake-compat = import (builtins.fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/9ed2ac151eada2306ca8c418ebd97807bb08f6ac.tar.gz";
    sha256 = "sha256:063slk1np1g1dkh21a82x655kpja7p4pc74rb3lqankyrbbpy4hx";
  });

in
{
  options = {
    partitionedAttrs = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        A set of flake output attributes that are taken from a partition instead of the default top level flake-parts evaluation.

        The attribute name refers to the flake output attribute name, and the value is the name of the partition to use.

        The flake attributes are overridden with `lib.mkForce` priority.

        See the `partitions` options to understand the purpose.
      '';
      example = {
        "devShells" = "dev";
        "checks" = "dev";
        "herculesCI" = "dev";
      };
    };
    partitions = mkOption {
      type = types.attrsOf (types.submodule partitionModule);
      default = { };
      description = ''
        By partitioning the flake, you can avoid fetching inputs that are not
        needed for the evaluation of a particular attribute.

        Each partition is a distinct module system evaluation. This allows
        attributes of the final flake to be defined by multiple sets of modules,
        so that for example the `packages` attribute can be evaluated without
        loading development related inputs.

        While the module system does a good job at preserving laziness, the fact
        that a development related import can define `packages` means that
        in order to evaluate `packages`, you need to evaluate at least to the
        point where you can conclude that the development related import does
        not actually define a `packages` attribute. While the actual evaluation
        is cheap, it can only happen after fetching the input, which is not
        as cheap.
      '';
      example = lib.literalExpression ''
        {
          dev = {
            extraInputsFlake = ./dev;
            module = ./dev/flake-module.nix;
          };
        }
      '';
    };
  };
  config = {
    # Default, overriden with specialArgs inside partitions.
    _module.args.partitionStack = [ ];
    flake = optionalAttrs (partitionStack == [ ]) (
      mapAttrs
        (attrName: partition: lib.mkForce (config.partitions.${partition}.module.flake.${attrName}))
        config.partitionedAttrs
    );
  };
}
