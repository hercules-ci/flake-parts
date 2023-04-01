# Nixpkgs module. The only exception to the rule.
# Provides a `pkgs` argument in `perSystem`.
topLevel@{ config, options, inputs, lib, flake-parts-lib, ... }:
let
  inherit (flake-parts-lib) mkPerSystemOption;

in
{
  imports = [ inputs.nixpkgs.flakeModules.default ];

  options = {
    perSystem = mkPerSystemOption ({ config, system, ... }:
      let
        finalOverlay = lib.composeManyExtensions
          # Last element has priority, so `perSystem` overlays rule
          (topLevel.config.nixpkgs.overlays ++ config.nixpkgs.overlays);

        finalPkgs = config.nixpkgs.mkPkgsFromArgs {
          localSystem = { inherit system; };
          overlays = [ finalOverlay ];
        };

      in
      {
        imports = [ inputs.nixpkgs.flakeModules.default ];
        _file = ./nixpkgs.nix;
        config = {
          _module.args.pkgs = lib.mkForce finalPkgs;
        };
      });
  };
}
