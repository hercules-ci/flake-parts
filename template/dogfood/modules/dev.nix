{flake-parts-lib, lib, inputs, ...}@topLevel: {
  imports = [
    ./hello.nix
    inputs.flake-parts.flakeModules.flakeModules
  ];
  flake.flakeModules.dev = {
    config.systems = [ "x86_64-linux" "aarch64-darwin" ];
    imports = [
      topLevel.config.flake.flakeModules.hello
    ];
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
