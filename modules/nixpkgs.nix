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
{
  config = {
    perSystem = { inputs', lib, ... }: {
      config = {
        _module.args.pkgs = lib.mkOptionDefault (
          builtins.seq
            (inputs'.nixpkgs or (throw "flake-parts: The flake does not have a `nixpkgs` input. Please add it, or set `perSystem._module.args.pkgs` yourself."))
            inputs'.nixpkgs.legacyPackages
        );
      };
    };
  };
}
