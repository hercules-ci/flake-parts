rec {
  f-p = builtins.getFlake (toString ../..);
  flake-parts = f-p;

  devFlake = builtins.getFlake (toString ../.);
  nixpkgs = devFlake.inputs.nixpkgs;

  f-p-lib = f-p.lib;

  inherit (f-p-lib) mkFlake;
  inherit (f-p.inputs.nixpkgs-lib) lib;

  pkg = system: name: derivation {
    name = name;
    builder = "no-builder";
    system = system;
  };

  empty = mkFlake
    { self = { }; }
    {
      systems = [ ];
    };

  example1 = mkFlake
    { self = { }; }
    {
      systems = [ "a" "b" ];
      perSystem = { system, ... }: {
        packages.hello = pkg system "hello";
      };
    };

  easyOverlay = mkFlake
    { self = { }; }
    {
      imports = [ flake-parts.flakeModules.easyOverlay ];
      systems = [ "a" ];
      perSystem = { system, config, final, pkgs, ... }: {
        packages.default = config.packages.hello;
        packages.hello = pkg system "hello";
        packages.hello_new = final.hello;
        overlayAttrs = {
          hello = config.packages.hello;
          hello_old = pkgs.hello;
          hello_new = config.packages.hello_new;
        };
      };
    };

  nixpkgsWithoutEasyOverlay = import nixpkgs {
    system = "x86_64-linux";
    overlays = [ ];
    config = { };
  };

  nixpkgsWithEasyOverlay = import nixpkgs {
    system = "x86_64-linux";
    overlays = [ easyOverlay.overlays.default ];
    config = { };
  };

  runTests = ok:

    assert empty == {
      apps = { };
      checks = { };
      devShells = { };
      formatter = { };
      legacyPackages = { };
      nixosConfigurations = { };
      nixosModules = { };
      overlays = { };
      packages = { };
    };

    assert example1 == {
      apps = { a = { }; b = { }; };
      checks = { a = { }; b = { }; };
      devShells = { a = { }; b = { }; };
      formatter = { };
      legacyPackages = { a = { }; b = { }; };
      nixosConfigurations = { };
      nixosModules = { };
      overlays = { };
      packages = {
        a = { hello = pkg "a" "hello"; };
        b = { hello = pkg "b" "hello"; };
      };
    };

    # - exported package becomes part of overlay.
    # - perSystem is invoked for the right system.
    assert nixpkgsWithEasyOverlay.hello == pkg "x86_64-linux" "hello";

    # - Non-exported package does not become part of overlay.
    assert nixpkgsWithEasyOverlay.default or null != pkg "x86_64-linux" "hello";

    # - hello_old comes from super
    assert nixpkgsWithEasyOverlay.hello_old == nixpkgsWithoutEasyOverlay.hello;

    # - `hello_new` shows that the `final` wiring works
    assert nixpkgsWithEasyOverlay.hello_new == nixpkgsWithEasyOverlay.hello;

    ok;

  result = runTests "ok";
}
