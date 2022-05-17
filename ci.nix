# We're doing things a bit differently because Nix doesn't let us
# split out the dev dependencies and subflakes are broken, let alone "superflakes".
# See dev/README.md
let
  flake = import ./dev;
  inherit (flake.inputs.nixpkgs) lib;
in
{
  inherit (flake) herculesCI;
} // {
  checks = lib.recurseIntoAttrs flake.checks.${builtins.currentSystem};
}
