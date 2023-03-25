{
  description = "Flake basics described using the module system";

  inputs = {
    nixpkgs-lib.url = "github:NixOS/nixpkgs/nixos-unstable?dir=lib";
  };

  outputs = { self, nixpkgs-lib, ... }: {
    lib = import ./lib.nix { inherit (nixpkgs-lib) lib; };
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
    };
    flakeModules = {
      easyOverlay = ./extras/easyOverlay.nix;
      flakeModules = ./extras/flakeModules.nix;
    };
  };

}
