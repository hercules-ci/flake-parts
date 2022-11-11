{ config, lib, ... }:
let
  inherit (lib)
    filterAttrs
    mapAttrs
    mkOption
    optionalAttrs
    types
    ;
in
{
  options = {
    flake = mkOption {
      type = types.submoduleWith {
        modules = [
          { freeformType = types.lazyAttrsOf types.raw; }
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
