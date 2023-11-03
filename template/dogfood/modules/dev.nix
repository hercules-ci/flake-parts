{flake-parts-lib, lib, inputs, ...}@topLevel:
rec {
  imports = [
    inputs.flake-parts.flakeModules.flakeModules

    # Use file name to dogfood a flake module defined from the current flake to avoid infinite recursion
    ./hello.nix

    {
      flake.flakeModules.dev.imports = [
        # Use attributes to reference the flake module from other flakes
        topLevel.config.flake.flakeModules.hello
      ];
    }

    # Reference `flake.flakeModules.dev` via `rec` instead of `config` to avoid infinite recursion
    flake.flakeModules.dev
  ];

  flake.flakeModules.dev = {
    config.systems = [ "x86_64-linux" "aarch64-darwin" ];

    options.perSystem = flake-parts-lib.mkPerSystemOption ({pkgs, ...}@perSystem: {
      devShells.default = pkgs.mkShell {
        buildInputs = [ perSystem.config.packages.hello_22_11 ];
        shellHook = ''
          hello
        '';
      };
    });
  };
}
