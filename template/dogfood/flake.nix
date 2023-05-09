{
  description = "Description for the project";

  inputs = {
    nixpkgs_22_11.url = "github:NixOS/nixpkgs/nixos-22.11";
  };

  outputs = { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      flake-parts.lib.mkFlake
        {
          # Workaround for https://github.com/hercules-ci/flake-parts/issues/148
          inputs = inputs // { self.outPath = ./.; };
        }
        ./modules/dogfood.nix
    ).flakeModules.dogfood;
}
