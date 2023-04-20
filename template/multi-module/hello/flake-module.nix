# Definitions can be imported from a separate file like this one

{ config, lib, inputs, ... }: {
  perSystem = { config, inputs', pkgs, ... }: {
    # Definitions like this are entirely equivalent to the ones
    # you may have directly in flake.nix.
    packages.hello = pkgs.hello;
  };
  flake = {
    nixosModules.hello = { pkgs, ... }: {
      environment.systemPackages = [
        # or inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.hello
        config.flake.packages.${pkgs.stdenv.hostPlatform.system}.hello
      ];
    };
  };
}
