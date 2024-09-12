{
  description = "Description for the project";

  inputs = {
    nixpkgs_23_05.url = "github:NixOS/nixpkgs/nixos-23.05";
  };

  outputs = { flake-parts, self, nixpkgs, ... }@inputs:
    flake-parts.lib.mkFlake
      {
        inherit inputs;
      }
      ({ config, lib, ... }: {
        imports = [
          flake-parts.flakeModules.partitions
          ./modules/dev.nix
        ];

        systems = [ "x86_64-linux" "aarch64-darwin" ];

        partitionedAttrs.devShells = "dogfood";
        partitionedAttrs.packages = "dogfood";
        partitions.dogfood = {
          module = {
            imports = [
              config.flake.flakeModules.dev
            ];
          };
        };
      });
}
