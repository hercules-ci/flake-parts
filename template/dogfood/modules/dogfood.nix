{flake-parts-lib, lib, inputs, ...}: {
  imports = [
    ./hello.nix
    inputs.flake-parts.flakeModules.flakeModules
  ];
  config.systems = [ "x86_64-linux" "aarch64-darwin" ];
  options.flake = lib.mkOption {
    type = lib.types.submoduleWith {
      modules = [
        (flake: {
          flakeModules.dogfood = {
            config.systems = [ "x86_64-linux" "aarch64-darwin" ];
            imports = [
              flake.config.flakeModules.hello

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
        })
      ];
    };
  };
}