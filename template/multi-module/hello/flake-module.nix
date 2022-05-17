
# Definitions can be imported from a separate file like this one

{ self, ... }: {
  perSystem = system: { config, self', inputs', ... }: {
    # Definitions like this are entirely equivalent to the ones
    # you may have directly in flake.nix.
    packages.hello = inputs'.nixpkgs.legacyPackages.hello;
  };
  flake = {
    nixosModules.hello = { pkgs, ... }: {
      environment.systemPackages = [
        # or self.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.hello
        self.packages.${pkgs.stdenv.hostPlatform.system}.hello
      ];
    };
  };
}