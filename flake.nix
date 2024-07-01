{
  description = "Flake basics described using the module system";

  inputs = {
    nixpkgs-lib.url = "https://github.com/NixOS/nixpkgs/archive/5daf0514482af3f97abaefc78a6606365c9108e2.tar.gz"; # 2741b4b489b55df32afac57bc4bfd220e8bf617e /lib from nixos-unstable
  };

  outputs = { nixpkgs-lib, ... }: {
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
    };
  };

}
