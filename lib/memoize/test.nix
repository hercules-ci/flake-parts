# Ad hoc manual test dependent on observing side effects
let
  lib = import ~/src/nixpkgs-master/lib;
  inherit (import ./memoize.nix { inherit lib; }) memoizeStr;
  # Don't use this in the wild, it's too expensive!
  printOnce = memoizeStr (x: builtins.trace "computing f ${lib.strings.escapeNixString x}" x);
in
{
  inherit printOnce memoizeStr lib;
}
