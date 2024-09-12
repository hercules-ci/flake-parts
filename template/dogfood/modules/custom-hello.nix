{ inputs, flake-parts-lib, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.flakeModules
  ];

  flake.flakeModules.customHello = {
    options.perSystem = flake-parts-lib.mkPerSystemOption ({ pkgs, system, ... }: {
      packages.hello =
        (inputs.nixpkgs_23_05.legacyPackages.${system}.hello.override {
          stdenv = pkgs.gcc11Stdenv;
        }).overrideAttrs (oldAttrs: {
          meta = oldAttrs.meta // {
            description = "A hello package from the `flakeModules.customHello` author's nixpkgs 23.05, built with gcc 11 from `flakeModules.customHello` user's nixpkgs";
          };
        });
    });
  };
}
