# Run with
#
#     nix build .#checks.x86_64-linux.eval-tests

{ flake-parts }:
rec {
  nixpkgs = flake-parts.inputs.nixpkgs;
  f-p-lib = flake-parts.lib;
  inherit (f-p-lib) mkFlake;
  inherit (flake-parts.inputs.nixpkgs-lib) lib;

  pkg = system: name:
    derivation
      {
        name = name;
        builder = "no-builder";
        system = system;
      }
    // {
      meta = {
        mainProgram = name;
      };
    };

  empty = mkFlake
    { inputs.self = { }; }
    {
      systems = [ ];
    };

  emptyExposeArgs = mkFlake
    { inputs.self = { outPath = "the self outpath"; }; }
    ({ config, moduleLocation, ... }: {
      flake = {
        inherit moduleLocation;
      };
    });

  emptyExposeArgsNoSelf = mkFlake
    { inputs.self = throw "self won't be available in case of some errors"; }
    ({ config, moduleLocation, ... }: {
      flake = {
        inherit moduleLocation;
      };
    });

  example1 = mkFlake
    { inputs.self = { }; }
    {
      systems = [ "a" "b" ];
      perSystem = { config, system, ... }: {
        packages.hello = pkg system "hello";
        apps.hello.program = config.packages.hello;
      };
    };

  packagesNonStrictInDevShells = mkFlake
    { inputs.self = packagesNonStrictInDevShells; /* approximation */ }
    {
      systems = [ "a" "b" ];
      perSystem = { system, self', ... }: {
        packages.hello = pkg system "hello";
        packages.default = self'.packages.hello;
        devShells = throw "can't be strict in perSystem.devShells!";
      };
      flake.devShells = throw "can't be strict in devShells!";
    };

  easyOverlay = mkFlake
    { inputs.self = { }; }
    {
      imports = [ flake-parts.flakeModules.easyOverlay ];
      systems = [ "a" "aarch64-linux" ];
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

  bundlersExample = mkFlake
    { inputs.self = { }; }
    {
      imports = [ flake-parts.flakeModules.bundlers ];
      systems = [ "a" "b" ];
      perSystem = { system, ... }: {
        packages.hello = pkg system "hello";
        bundlers.toTarball = drv: pkg system "tarball-${drv.name}";
        bundlers.toAppImage = drv: pkg system "appimage-${drv.name}";
      };
    };

  modulesFlake =
    mkFlake
      {
        inputs.self = { };
        moduleLocation = "modulesFlake";
      }
      {
        imports = [ flake-parts.flakeModules.modules ];
        options = {
          # Test option that uses plain types.submodule
          flake.fooConfiguration = lib.mkOption {
            type = lib.types.submoduleWith {
              # Just Like types.submodule;
              shorthandOnlyDefinesConfig = true;
              class = "foo";
              modules = [ ];
            };
          };
        };
        config = {
          systems = [ ];
          flake = {
            modules.generic.example =
              { lib, ... }:
              {
                options.generic.example = lib.mkOption { default = "works in any module system application"; };
              };
            modules.foo.example =
              { lib, ... }:
              {
                options.foo.example = lib.mkOption { default = "works in foo application"; };
              };
            fooConfiguration = modulesFlake.modules.foo.example;
          };
        };
      };

  flakeModulesDeclare = mkFlake
    { inputs.self = { outPath = ./.; }; }
    ({ config, ... }: {
      imports = [ flake-parts.flakeModules.flakeModules ];
      systems = [ ];
      flake.flakeModules.default = { lib, ... }: {
        options.flake.test123 = lib.mkOption { default = "option123"; };
        imports = [ config.flake.flakeModules.extra ];
      };
      flake.flakeModules.extra = {
        flake.test123 = "123test";
      };
    });

  flakeModulesImport = mkFlake
    { inputs.self = { }; }
    {
      imports = [ flakeModulesDeclare.flakeModules.default ];
    };

  flakeModulesDisable = mkFlake
    { inputs.self = { }; }
    {
      imports = [ flakeModulesDeclare.flakeModules.default ];
      disabledModules = [ flakeModulesDeclare.flakeModules.extra ];
    };

  nixpkgsWithoutEasyOverlay = import nixpkgs {
    system = "x86_64-linux";
    overlays = [ ];
    config = { };
  };

  nixpkgsWithEasyOverlay = import nixpkgs {
    # non-memoized
    system = "x86_64-linux";
    overlays = [ easyOverlay.overlays.default ];
    config = { };
  };

  nixpkgsWithEasyOverlayMemoized = import nixpkgs {
    # memoized
    system = "aarch64-linux";
    overlays = [ easyOverlay.overlays.default ];
    config = { };
  };

  specialArgFlake = mkFlake
    {
      inputs.self = { };
      specialArgs.soSpecial = true;
    }
    ({ soSpecial, ... }: {
      imports = assert soSpecial; [ ];
      flake.foo = true;
    });

  partitionWithoutExtraInputsFlake = mkFlake
    {
      inputs.self = { };
    }
    ({ config, ... }: {
      imports = [ flake-parts.flakeModules.partitions ];
      systems = [ "x86_64-linux" ];
      partitions.dev.module = { inputs, ... }: builtins.seq inputs { };
      partitionedAttrs.devShells = "dev";
    });

  nixosModulesFlake = mkFlake
    {
      inputs.self = { outPath = "/test/path"; };
    }
    {
      systems = [ ];
      flake.nixosModules.example = { lib, ... }: {
        options.test.option = lib.mkOption { default = "nixos-test"; };
      };
    };

  /**
    This one is for manual testing. Should look like:

    ```
    nix-repl> checks.x86_64-linux.eval-tests.internals.printSystem.withSystem "foo" ({ config, ... }: null)
    trace: Evaluating perSystem for foo
    null

    nix-repl> checks.x86_64-linux.eval-tests.internals.printSystem.withSystem "foo" ({ config, ... }: null)
    null

    ```
  */
  printSystem = mkFlake
    { inputs.self = { }; }
    ({ withSystem, ... }: {
      systems = [ ];
      perSystem = { config, system, ... }:
        builtins.trace "Evaluating perSystem for ${system}" { };
      flake.withSystem = withSystem;
    });

  dogfoodProvider = mkFlake
    { inputs.self = { }; }
    ({ flake-parts-lib, ... }: {
      imports = [
        (flake-parts-lib.importAndPublish "dogfood" { flake.marker = "dogfood"; })
      ];
    });

  dogfoodConsumer = mkFlake
    { inputs.self = { }; }
    ({ flake-parts-lib, ... }: {
      imports = [
        dogfoodProvider.modules.flake.dogfood
      ];
    });

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
      apps = {
        a = {
          hello = {
            program = "${pkg "a" "hello"}/bin/hello";
            type = "app";
            meta = { };
          };
        };
        b = {
          hello = {
            program = "${pkg "b" "hello"}/bin/hello";
            type = "app";
            meta = { };
          };
        };
      };
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

    assert bundlersExample.bundlers.a.toTarball (pkg "a" "hello") == pkg "a" "tarball-hello";
    assert bundlersExample.bundlers.b.toAppImage (pkg "b" "hello") == pkg "b" "appimage-hello";

    # - exported package becomes part of overlay.
    # - perSystem is invoked for the right system, when system is non-memoized
    assert nixpkgsWithEasyOverlay.hello == pkg "x86_64-linux" "hello";

    # - perSystem is invoked for the right system, when system is memoized
    assert nixpkgsWithEasyOverlayMemoized.hello == pkg "aarch64-linux" "hello";

    # - Non-exported package does not become part of overlay.
    assert nixpkgsWithEasyOverlay.default or null != pkg "x86_64-linux" "hello";

    # - hello_old comes from super
    assert nixpkgsWithEasyOverlay.hello_old == nixpkgsWithoutEasyOverlay.hello;

    # - `hello_new` shows that the `final` wiring works
    assert nixpkgsWithEasyOverlay.hello_new == nixpkgsWithEasyOverlay.hello;

    assert flakeModulesImport.test123 == "123test";

    assert flakeModulesDisable.test123 == "option123";

    assert packagesNonStrictInDevShells.packages.a.default == pkg "a" "hello";

    assert emptyExposeArgs.moduleLocation == "the self outpath/flake.nix";

    assert (lib.evalModules {
      class = "barrr";
      modules = [
        modulesFlake.modules.generic.example
      ];
    }).config.generic.example == "works in any module system application";

    assert (lib.evalModules {
      class = "foo";
      modules = [
        modulesFlake.modules.foo.example
      ];
    }).config.foo.example == "works in foo application";

    # Test that modules can be loaded into plain submodules with shorthandOnlyDefinesConfig = true
    assert modulesFlake.fooConfiguration.foo.example == "works in foo application";

    assert specialArgFlake.foo;

    assert builtins.isAttrs partitionWithoutExtraInputsFlake.devShells.x86_64-linux;

    assert nixosModulesFlake.nixosModules.example._class == "nixos";

    assert nixosModulesFlake.nixosModules.example._file == "/test/path/flake.nix#nixosModules.example";

    assert (lib.evalModules {
      class = "nixos";
      modules = [
        nixosModulesFlake.nixosModules.example
      ];
    }).config.test.option == "nixos-test";

    assert dogfoodProvider.marker == "dogfood";
    assert dogfoodConsumer.marker == "dogfood";

    ok;

  result = runTests "ok";
}
