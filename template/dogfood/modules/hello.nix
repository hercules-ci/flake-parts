{inputs, flake-parts-lib, ...}:
rec {
  imports = [
    inputs.flake-parts.flakeModules.flakeModules

    # Reference `flake.flakeModules.hello` via `rec` instead of `config` to avoid infinite recursion
    flake.flakeModules.hello
  ];

  flake.flakeModules.hello = {
    options.perSystem = flake-parts-lib.mkPerSystemOption ({ system, ... }: {
      packages.hello_22_11 =
        inputs.nixpkgs_23_05.legacyPackages.${system}.hello;
    });
  };
}
