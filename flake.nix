{
  description = "Flake basics described using the module system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: {
    lib = import ./lib.nix { inherit (nixpkgs) lib; };
    flakeModules = {
      core = ./all-modules.nix;
    };
  };

}
