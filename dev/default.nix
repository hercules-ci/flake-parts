let
  flake = builtins.getFlake (toString ./.);
  fmc-lib = import ../lib.nix { inherit (flake.inputs.nixpkgs) lib; };
  self = {
    inherit (flake) inputs;
    outPath = ../.; # used by pre-commit module, etc
  } //
  fmc-lib.evalFlakeModule
    { inherit self; }
    ./flake-module.nix;
in
  self.config.flake // { inherit (flake) inputs; }
