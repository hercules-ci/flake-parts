{
  description = "Description for the project";

  inputs = {
    nixpkgs_23_05.url = "github:NixOS/nixpkgs/nixos-23.05";
  };

  outputs = { flake-parts, self, nixpkgs, ... }@inputs:
    flake-parts.lib.mkFlake
      {
        inherit inputs;
        moduleLocation = ./flake.nix;
      }
      {
        imports = [
          ./modules/anotherFlakeModule.nix
          ./modules/dev.nix
        ];
      };
}
