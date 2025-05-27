{ config, lib, options, docsVisible, ... }:
let
  inherit (lib)
    addErrorContext
    concatMapAttrs
    evalModules
    mkOption
    types
    ;

  unNull = v:
    if v == null then
      { }
    else
      v;

  touchupAttrs =
    v:
    concatMapAttrs
      (name: value:
      let
        eval = evalModules {
          prefix = lib.lists.init options.attr.loc; # arbitrary pick
          specialArgs = {
            attrName = name;
          };
          modules = [
            (config.attr.${name} or ./attr.nix)
            (unNull config.any)
          ];
        };
      in
      if addErrorContext "while figuring out whether to enable '${name}'" eval.config.enable then
      # Apply the touchup configuration to the value.
        {
          "${name}" =
            addErrorContext "while touching up attribute '${name}'" (
              (addErrorContext "while evaluating the touchup configuration for '${name}'" eval.config.touchupApply)
                (addErrorContext "while evaluating the original value of '${name}'" value)
            );
        }
      else
        { }
      )
      v;
in
{
  options = {
    attr = mkOption {
      type = types.lazyAttrsOf (types.deferredModuleWith {
        staticModules = [ ./attr.nix ];
      });
      default = { };
      visible = docsVisible;
      description = ''
        By defining an attribute in this set, you can apply a touchup to the value of that attribute in the processed flake.

        Inside of this is another touchup structure that is applied to the value of the attribute.
        ${lib.optionalString (docsVisible == "shallow") " Its option documentation is the same - not repeated here."}

        This module is called with module argument `attrName`, which is the name of the attribute being touched up.
      '';
    };
    any = mkOption {
      type = types.nullOr (types.deferredModuleWith {
        staticModules = [ ./attr.nix ];
      });
      default = null;
      visible = docsVisible;
      description = ''
        A touchup that applies to all attributes, in addition to what is defined in `attr.<name>`.
        It only matches one layer.

        Inside of this is another touchup structure that is applied to the value of the attribute.
        ${lib.optionalString (docsVisible == "shallow") " Its option documentation is the same - not repeated here."}

        This module is called with module argument `attrName`, which is the name of the attribute being touched up.
      '';
    };

    type = mkOption {
      type = types.raw;
      default = types.raw;
      defaultText = "raw";
      description = ''
        A type to apply to the result of ${options.finish}.
        This adds a merging capability if you have overlapping `finish` definitions in multiple modules.
      '';
    };
    finish = mkOption {
      type = types.functionTo config.type;
      default = v: v;
      defaultText = lib.literalMD "`v: v`, the identity function";
      description = ''
        A function to apply after handling ${options.attr} and ${options.any}.
      '';
    };

    touchupApply = mkOption {
      internal = true;
      description = ''
        A generated function that applies the touchups that are configured with the other options in this module.
      '';
      type = types.functionTo types.raw;
      readOnly = true;
    };
  };
  config = {
    _module.args.docsVisible = lib.mkDefault true;
    touchupApply = v:
      config.finish
        (if config.attr != { } || config.any != null
        then
          addErrorContext "while applying touchups from ${options.attr}: ${lib.options.showDefs options.attr.definitionsWithLocations}\n  and from ${options.any}: ${lib.options.showDefs options.any.definitionsWithLocations}"
            (touchupAttrs v)
        else v);
  };
}

