{
  description = "Flake basics described using the module system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: {
    lib = import ./lib.nix { inherit (nixpkgs) lib; };
    templates = {
      default = {
        path = ./template/default;
        description = ''
          A minimal flake using flake-modules-core.
        '';
      };
      multi-module = {
        path = ./template/multi-module;
        description = ''
          A minimal flake using flake-modules-core.
        '';
      };
    };
  };

}
