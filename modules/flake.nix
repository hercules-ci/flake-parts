{ lib, ... }:
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
      '';
    };
  };
}
