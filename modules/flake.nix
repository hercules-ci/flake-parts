{ config, lib, options, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
in
{
  options = {
    flake = mkOption {
      type = types.submoduleWith {
        modules = [
          {
            freeformType =
              types.lazyAttrsOf
                (types.unique
                  {
                    message = ''
                      No option has been declared for this flake output attribute, so its definitions can't be merged automatically.
                      Possible solutions:
                        - Load a module that defines this flake output attribute
                          Many modules are listed at https://flake.parts
                        - Declare an option for this flake output attribute
                        - Make sure the output attribute is spelled correctly
                        - Define the value only once, with a single definition in a single module
                    '';
                  }
                  types.raw);
          }
        ];
      };
      description = ''
        Raw flake output attributes. Any attribute can be set here, but some
        attributes are represented by options, to provide appropriate
        configuration merging.

        Further processing may be applied to these attributes. See [`processedFlake`](flake-parts.md#opt-processedFlake) for more information.
      '';
    };
    processedFlake = mkOption {
      type = types.raw;
      readOnly = true;
      apply =
        if options.processedFlake.isDefined
        then x: x
        else x: config.flake;
      description = ''
        The final flake output, as returned by `mkFlake`.

        This separates two concerns:

        - [`flake`](#opt-flake): the internal representation, where all attributes are available for use by other modules, regardless of whether they evaluate successfully for all configurations.
        - `processedFlake`: the external output, which may have attributes removed or transformed to satisfy tools like `nix flake check`.

        By default, `processedFlake` equals `flake` (no processing).
        Import a module such as [`flakeModules.touchup`](flake-parts-touchup.md#opt-touchup) to define it, or set it directly.
      '';
    };
  };
}
