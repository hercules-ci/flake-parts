{flake-parts-lib, lib, inputs, ...}@topLevel: 
rec {
  imports = [
    inputs.flake-parts.flakeModules.flakeModules
    flake.flakeModules.dev

    # Use file name to dogfood a flake module defined from the current flake to avoid infinite recursion
    ./hello.nix
  ];
  flake.flakeModules.dev = dev: {
    imports = lib.lists.optionals (topLevel.moduleLocation != dev.moduleLocation) [
      # Use attributes to reference the flake module from other flakes
      topLevel.config.flake.flakeModules.hello
    ];

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
