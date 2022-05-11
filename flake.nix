{
  description = "Flake basics described using the module system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: {
    lib = import ./lib.nix { inherit (nixpkgs) lib; };
    defaultTemplate = {
      path = ./template/default;
      description = ''
        A minimal flake using flake-modules-core.
      '';
    };
  };

}
