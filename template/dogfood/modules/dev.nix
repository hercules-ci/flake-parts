{flake-parts-lib, lib, inputs, ...}@topLevel: 
rec {
  imports = [
    inputs.flake-parts.flakeModules.flakeModules
    flake.flakeModules.dev
  ];
  flake.flakeModules.dev = dev: {
    config.systems = [ "x86_64-linux" "aarch64-darwin" ];
    imports = [
      (
        if topLevel.moduleLocation == dev.moduleLocation
        then ./hello.nix # Use file name to dogfood a flake module defined from the current flake to avoid infinite recursion
        else topLevel.config.flake.flakeModules.hello # Use attributes to reference the flake module from other flakes
      )
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
