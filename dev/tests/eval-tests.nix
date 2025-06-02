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

  modulesFlake = mkFlake
    {
      inputs.self = { };
      moduleLocation = "modulesFlake";
    }
    {
      imports = [ flake-parts.flakeModules.modules ];
      systems = [ ];
      flake = {
        modules.generic.example = { lib, ... }: {
          options.generic.example = lib.mkOption { default = "works in any module system application"; };
        };
        modules.foo.example = { lib, ... }: {
          options.foo.example = lib.mkOption { default = "works in foo application"; };
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

  touchup1 = mkFlake
    { inputs.self = { }; }
    {
      imports = [ flake-parts.flakeModules.touchup ];
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      touchup.any = { attrName, ... }: { enable = attrName == "overlays"; };
      perSystem = { config, ... }: {
        packages.default = throw "packages.default should not be evaluated";
        packages.hello = throw "packages.hello should not be evaluated";
      };
    };

  touchup1b = mkFlake
    { inputs.self = { }; }
    {
      imports = [ flake-parts.flakeModules.touchup ];
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      touchup.any = { attrName, ... }: { enable = lib.mkDefault false; };
      touchup.attr.overlays = { enable = true; };
      perSystem = { config, ... }: {
        packages.default = throw "packages.default should not be evaluated";
        packages.hello = throw "packages.hello should not be evaluated";
      };
    };

  touchup2 = mkFlake
    { inputs.self = { }; }
    {
      imports = [ flake-parts.flakeModules.touchup ];
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      touchup.attr.packages.attr.aarch64-darwin.attr.bar.enable = false;
      perSystem = { config, system, ... }: {

        packages.foo = pkg system "foo";
        packages.bar = assert system == "x86_64-linux"; pkg system "bar";

      };
    };

  touchup3 = mkFlake
    { inputs.self = { }; }
    {
      imports = [ flake-parts.flakeModules.touchup ];
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      touchup.any = { attrName, ... }: { enable = lib.mkDefault false; };
      touchup.attr.overlays = { enable = true; finish = x: "hoi"; };
      touchup.finish = x: x // { foo = "bar"; };
    };

  runTests = ok:

    assert touchup1 == {
      overlays = { };
    };
    assert touchup1b == {
      overlays = { };
    };

    assert builtins.attrNames touchup2 == [ "apps" "checks" "devShells" "formatter" "legacyPackages" "nixosConfigurations" "nixosModules" "overlays" "packages" ];
    assert touchup2.packages ==
      {
        aarch64-darwin = { foo = pkg "aarch64-darwin" "foo"; };
        x86_64-linux = { foo = pkg "x86_64-linux" "foo"; bar = pkg "x86_64-linux" "bar"; };
      };

    assert touchup3 == {
      overlays = "hoi";
      foo = "bar";
    };

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

    assert specialArgFlake.foo;

    assert builtins.isAttrs partitionWithoutExtraInputsFlake.devShells.x86_64-linux;

    ok;

  result =
    builtins.addErrorContext "while running eval-tests" (
      runTests "ok"
    );
}
