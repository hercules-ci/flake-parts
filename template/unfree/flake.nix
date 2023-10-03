{
  description = "Description for the project";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      # This sets `pkgs` to a Nixpkgs with the `allowUnfree` option set.
      nixpkgs.settings.config.allowUnfree = true;
      perSystem = { pkgs, system, ... }: {
        packages.default = pkgs.hello-unfree;
      };
    };
}
