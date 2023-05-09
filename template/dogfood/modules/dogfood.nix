{flake-parts-lib, lib, inputs, ...}@topLevel: {
  imports = [
    ./hello.nix
    inputs.flake-parts.flakeModules.flakeModules
  ];
  flake.flakeModules.dogfood = {
    config.systems = [ "x86_64-linux" "aarch64-darwin" ];
    imports = [
      topLevel.config.flake.flakeModules.hello

      # Expose flake modules
      ./dogfood.nix
      ./hello.nix
      ./anotherFlakeModule.nix
    ];
    options.perSystem = flake-parts-lib.mkPerSystemOption (perSystem: {
      apps.default = {
        type = "app";
        program = "${perSystem.config.packages.hello_22_11}/bin/hello";
      };
    });
  };
}
