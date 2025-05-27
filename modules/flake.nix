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
        Nix is a lazily evaluated language, also known as non-strict, which is not just a more accurate term, but also a bit descriptive of the programming style that is supported:
        it is ok to have variables can not be evaluated successfully.

        This is a useful pattern that makes expression logic simpler and more robust, but it doesn't entirely remove the need to specify what's supposed to work and what may not work.
        Specifically `nix flake check` will evaluate whatever it finds and understands, but redundant failing attributes can also annoy users.

        So this is where `processedFlake` comes in: it is the final output of a flake-parts flake, specifically for the purpose of external consumption.
        It's a separation of concerns:

        - `flake`: configuration and programming, where we keep everything around, to keep things simple and avoid inducing undesirable strictness by filtering things away too soon.
        - `processedFlake`: the final output, which is a valid flake, and which is used by `nix flake check` and other tools.

        By default, no processing is done, so `processedFlake` is the same as `flake`.
        You may define `processedFlake` manually, or import a module that defines it in a convenient, perhaps composable way.
      '';
    };
  };
}
