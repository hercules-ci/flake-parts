{
  description = "Description for the project";

  inputs = {
    nixpkgs_22_11.url = "github:NixOS/nixpkgs/nixos-22.11";
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
