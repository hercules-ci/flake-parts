{inputs, ...}: {
  imports = [
    inputs.flake-parts.flakeModules.flakeModules
  ];
  flake.flakeModules.anotherFlakeModule = {
    # Define another flake module here
  };
}