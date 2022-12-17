let
  flake = builtins.getFlake (toString ./.);
  fmc-lib = (builtins.getFlake (toString ../.)).lib;
  args = {
    inherit self;
  } // flake.inputs;
  self = {
    inherit (flake) inputs;
    outPath = ../.; # used by pre-commit module, etc
    outputs = self.config.flake;
  } //
  fmc-lib.mkFlake
    { inputs = args; }
    ./flake-module.nix;
in
self.config.flake // { inherit (flake) inputs; }
