{inputs, flake-parts-lib, ...}:
rec {
  imports = [
    inputs.flake-parts.flakeModules.flakeModules
    flake.flakeModules.hello
  ];

  flake.flakeModules.hello = {
    options.perSystem = flake-parts-lib.mkPerSystemOption ({ system, ... }: {
      packages.hello_22_11 =
        inputs.nixpkgs_22_11.legacyPackages.${system}.hello;
    });
  };
}