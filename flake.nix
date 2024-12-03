{
  description = "Flake basics described using the module system";

  inputs = {
    nixpkgs-lib.url = "https://github.com/NixOS/nixpkgs/archive/5487e69da40cbd611ab2cadee0b4637225f7cfae.tar.gz"; # 970e93b9f82e2a0f3675757eb0bfc73297cc6370 /lib from nixos-unstable
  };

  outputs = inputs@{ nixpkgs-lib, ... }:
    let
      lib = import ./lib.nix {
        inherit (nixpkgs-lib) lib;
        # Extra info for version check message
        revInfo =
          if nixpkgs-lib?rev
          then " (nixpkgs-lib.rev: ${nixpkgs-lib.rev})"
          else "";
      };
      templates = {
        default = {
          path = ./template/default;
          description = ''
            A minimal flake using flake-parts.
          '';
        };
        multi-module = {
          path = ./template/multi-module;
          description = ''
            A minimal flake using flake-parts.
          '';
        };
        unfree = {
          path = ./template/unfree;
          description = ''
            A minimal flake using flake-parts importing nixpkgs with the unfree option.
          '';
        };
        package = {
          path = ./template/package;
          description = ''
            A flake with a simple package:
            - Nixpkgs
            - callPackage
            - src with fileset
            - a check with runCommand
          '';
        };
      };
      flakeModules = {
        easyOverlay = ./extras/easyOverlay.nix;
        flakeModules = ./extras/flakeModules.nix;
        modules = ./extras/modules.nix;
        partitions = ./extras/partitions.nix;
      };
    in
    lib.mkFlake { inherit inputs; } {
      systems = [ ];
      imports = [ flakeModules.partitions ];
      partitionedAttrs.checks = "dev";
      partitionedAttrs.devShells = "dev";
      partitionedAttrs.herculesCI = "dev";
      partitions.dev.extraInputsFlake = ./dev;
      partitions.dev.module = {
        imports = [ ./dev/flake-module.nix ];
      };
      flake = {
        inherit lib templates flakeModules;
      };
    };

}
