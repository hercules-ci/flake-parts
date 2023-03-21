#
# Nixpkgs module. The only exception to the rule.
#
# Provides a `pkgs` argument in `perSystem`.
#
# Arguably, this shouldn't be in flake-parts, but in nixpkgs.
# Nixpkgs could define its own module that does this, which would be
# a more consistent UX, but for now this will do.
#
# The existence of this module does not mean that other flakes' logic
# will be accepted into flake-parts, because it's against the
# spirit of Flakes.
#
{ config, inputs, lib, ... }:
{
  config = {
    imports = [ inputs.nixpkgs.flakeModule ];
    perSystem = { ... }: {
      config = {
        _module.args.pkgs = lib.mkOptionDefault config.nixpkgs.output;
      };
    };
  };
}
