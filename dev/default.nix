let
  flake = builtins.getFlake (toString ./.);
  fmc-lib = import ../lib.nix { inherit (flake.inputs.nixpkgs) lib; };
  self = { inherit (flake) inputs; } // 
    fmc-lib.evalFlakeModule
      { inherit self; }
      ./flake-module.nix;
in
  self.config.flake // { inherit (flake) inputs; }
