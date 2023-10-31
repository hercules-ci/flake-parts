{
  description = "Description for the project";

  inputs = {
    nixpkgs_22_11.url = "github:NixOS/nixpkgs/nixos-22.11";
  };

  outputs = { flake-parts, self, ... }@inputs: let
    bootstrap = 
      flake-parts.lib.mkFlake
        {
          inherit inputs;
          moduleLocation = ./flake.nix;
        }
        ./modules/dogfood.nix;
  in
    flake-parts.lib.mkFlake { inherit inputs; } bootstrap.flakeModules.dogfood;
}
