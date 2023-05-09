{
  description = "Description for the project";

  inputs = {
    nixpkgs_22_11.url = "github:NixOS/nixpkgs/nixos-22.11";
  };

  outputs = { flake-parts, self, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      flake-parts.lib.mkFlake
        {
          inherit inputs;
          # Workaround for https://github.com/hercules-ci/flake-parts/issues/148
          self = {
            outPath = ./.;
            inherit (self)
              _type inputs lastModified lastModifiedDate narHash outputs sourceInfo submodules;
          };
        }
        ./modules/dogfood.nix
    ).flakeModules.dogfood;
}
