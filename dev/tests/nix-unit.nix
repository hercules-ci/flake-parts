# Tests in nix-unit format
# Run with:
#   nix-unit --flake .#tests
# or:
#   nix build .#checks.x86_64-linux.nix-unit
#
# NOTE: Derivation comparison
# nix-unit deeply forces both `expr` and `expected` (via forceValueDeep) before
# comparing. The attrsets returned by `derivation` are self-referential, so
# this causes stack overflow. We compare `.drvPath` instead where needed, like
# `==` does when `.type == "derivation"`.

{ flake-parts }:
let
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

  # Replace derivations with a simple attrset so nix-unit can compare without
  # hitting stack overflow on self-referential derivation attrsets.
  # See NOTE: Derivation comparison
  canon = v:
    if v.type or null == "derivation" then { type = "derivation"; inherit (v) drvPath outPath name system; }
    else if builtins.isAttrs v then builtins.mapAttrs (_: canon) v
    else v;

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

  # Originally tested errorLocation (removed in c8c8e56). Repurposed to test
  # that mkFlake can produce standard outputs without forcing self.
  emptyExposeArgsNoSelf = mkFlake
    { inputs.self = throw "self won't be available in case of some errors"; }
    {
      systems = [ ];
    };

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

  flakeModulesFromModules = mkFlake
    { inputs.self = { outPath = ./.; }; }
    ({ config, ... }: {
      imports = [
        flake-parts.flakeModules.flakeModules
        flake-parts.flakeModules.modules
      ];
      systems = [ ];
      flake.modules.flake.default = { lib, ... }: {
        options.flake.test123 = lib.mkOption { default = "option123"; };
        imports = [ config.flake.flakeModules.extra ];
      };
      flake.modules.flake.extra = {
        flake.test123 = "123test";
      };
      flake.flakeModules = config.flake.modules.flake;
    });

  disableBuiltinModule = mod: mkFlake
    { inputs.self = { }; }
    {
      systems = [ "x86_64-linux" ];
      disabledModules = [ mod ];
    };

  flakeModulesImport = mkFlake
    { inputs.self = { }; }
    {
      imports = [ flakeModulesDeclare.flakeModules.default ];
    };

  flakeModulesImportFromFromModules = mkFlake
    { inputs.self = { }; }
    {
      imports = [ flakeModulesFromModules.flakeModules.default ];
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

  withSystemFlake = mkFlake
    { inputs.self = { }; }
    ({ withSystem, ... }: {
      systems = [ "a" "b" ];
      perSystem = { system, ... }: {
        packages.hello = pkg system "hello";
      };
      flake.withSystem = withSystem;
    });

in
{
  "test: mkFlake does not force self" = {
    expr = emptyExposeArgsNoSelf;
    expected = {
      apps = { };
      checks = { };
      devShells = { };
      formatter = { };
      legacyPackages = { };
      nixosConfigurations = { };
      nixosModules = { };
      overlays = { };
      packages = { };
      templates = { };
    };
  };

  withSystem = {
    "test: withSystem provides the right system for undeclared system" = {
      expr = withSystemFlake.withSystem "foo" ({ system, ... }: system);
      expected = "foo";
    };
    "test: withSystem provides perSystem config for undeclared system" = {
      expr = withSystemFlake.withSystem "foo" ({ config, ... }: config.packages.hello);
      expected = pkg "foo" "hello";
    };
    "test: withSystem provides the right system for declared system" = {
      expr = withSystemFlake.withSystem "a" ({ system, ... }: system);
      expected = "a";
    };
    "test: withSystem provides perSystem config for declared system" = {
      expr = withSystemFlake.withSystem "a" ({ config, ... }: config.packages.hello);
      expected = pkg "a" "hello";
    };
  };
  empty = {
    "test: empty flake outputs" = {
      expr = empty;
      expected = {
        apps = { };
        checks = { };
        devShells = { };
        formatter = { };
        legacyPackages = { };
        nixosConfigurations = { };
        nixosModules = { };
        overlays = { };
        packages = { };
        templates = { };
      };
    };
  };

  example1 = {
    "test: full flake output with two systems" = {
      expr = example1;
      expected = {
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
        templates = { };
        packages = {
          a = { hello = pkg "a" "hello"; };
          b = { hello = pkg "b" "hello"; };
        };
      };
    };
  };

  bundlers = {
    "test: toTarball bundler" = {
      expr = bundlersExample.bundlers.a.toTarball (pkg "a" "hello");
      expected = pkg "a" "tarball-hello";
    };
    "test: toAppImage bundler" = {
      expr = bundlersExample.bundlers.b.toAppImage (pkg "b" "hello");
      expected = pkg "b" "appimage-hello";
    };
  };

  easyOverlay = {
    "test: exported package in overlay, perSystem invoked for non-memoized system" = {
      expr = nixpkgsWithEasyOverlay.hello;
      expected = pkg "x86_64-linux" "hello";
    };

    "test: exported package in overlay, perSystem invoked for memoized system" = {
      expr = nixpkgsWithEasyOverlayMemoized.hello;
      expected = pkg "aarch64-linux" "hello";
    };

    "test: non-exported package not in overlay" = {
      expr = nixpkgsWithEasyOverlay.default or null != pkg "x86_64-linux" "hello";
      expected = true;
    };

    "test: hello_old comes from super" = {
      expr = nixpkgsWithEasyOverlay.hello_old.drvPath;
      # See NOTE: Derivation comparison
      expected = nixpkgsWithoutEasyOverlay.hello.drvPath;
    };

    "test: hello_new uses final wiring" = {
      expr = nixpkgsWithEasyOverlay.hello_new.drvPath;
      # See NOTE: Derivation comparison
      expected = nixpkgsWithEasyOverlay.hello.drvPath;
    };
  };

  flakeModules = {
    "test: import flakeModule" = {
      expr = flakeModulesImport.test123;
      expected = "123test";
    };

    "test: import flakeModuleFromFromModules" = {
      expr = flakeModulesImportFromFromModules.test123;
      expected = "123test";
    };

    "test: disable flakeModule" = {
      expr = flakeModulesDisable.test123;
      expected = "option123";
    };

    # Basic module disable checks. These aren't particularly thorough, but since
    # these "interface" modules don't tend to interact, that should be ok for now.
    "test: disable built-in apps" = {
      expr = builtins.attrNames (disableBuiltinModule flake-parts.flakeModules.apps);
      expected = builtins.filter (n: n != "apps") (builtins.attrNames empty);
    };
    "test: disable built-in checks" = {
      expr = builtins.attrNames (disableBuiltinModule flake-parts.flakeModules.checks);
      expected = builtins.filter (n: n != "checks") (builtins.attrNames empty);
    };
    "test: disable built-in devShells" = {
      expr = builtins.attrNames (disableBuiltinModule flake-parts.flakeModules.devShells);
      expected = builtins.filter (n: n != "devShells") (builtins.attrNames empty);
    };
    "test: disable built-in formatter" = {
      expr = builtins.attrNames (disableBuiltinModule flake-parts.flakeModules.formatter);
      expected = builtins.filter (n: n != "formatter") (builtins.attrNames empty);
    };
    "test: disable built-in legacyPackages" = {
      expr = builtins.attrNames (disableBuiltinModule flake-parts.flakeModules.legacyPackages);
      expected = builtins.filter (n: n != "legacyPackages") (builtins.attrNames empty);
    };
    "test: disable built-in nixosConfigurations" = {
      expr = builtins.attrNames (disableBuiltinModule flake-parts.flakeModules.nixosConfigurations);
      expected = builtins.filter (n: n != "nixosConfigurations") (builtins.attrNames empty);
    };
    "test: disable built-in nixosModules" = {
      expr = builtins.attrNames (disableBuiltinModule flake-parts.flakeModules.nixosModules);
      expected = builtins.filter (n: n != "nixosModules") (builtins.attrNames empty);
    };
    "test: disable built-in overlays" = {
      expr = builtins.attrNames (disableBuiltinModule flake-parts.flakeModules.overlays);
      expected = builtins.filter (n: n != "overlays") (builtins.attrNames empty);
    };
    "test: disable built-in packages" = {
      expr = builtins.attrNames (disableBuiltinModule flake-parts.flakeModules.packages);
      expected = builtins.filter (n: n != "packages") (builtins.attrNames empty);
    };
  };

  "test: packages not strict in devShells" = {
    expr = packagesNonStrictInDevShells.packages.a.default;
    expected = pkg "a" "hello";
  };

  "test: moduleLocation from self outPath" = {
    expr = emptyExposeArgs.moduleLocation;
    expected = "the self outpath/flake.nix";
  };

  modules = {
    "test: generic module in arbitrary class" = {
      expr = (lib.evalModules {
        class = "barrr";
        modules = [
          modulesFlake.modules.generic.example
        ];
      }).config.generic.example;
      expected = "works in any module system application";
    };

    "test: foo module in foo class" = {
      expr = (lib.evalModules {
        class = "foo";
        modules = [
          modulesFlake.modules.foo.example
        ];
      }).config.foo.example;
      expected = "works in foo application";
    };

    "test: modules in submodule with shorthandOnlyDefinesConfig" = {
      expr = modulesFlake.fooConfiguration.foo.example;
      expected = "works in foo application";
    };
  };

  "test: specialArgs passed to module" = {
    expr = specialArgFlake.foo;
    expected = true;
  };

  "test: partition without extra inputs" = {
    expr = builtins.isAttrs partitionWithoutExtraInputsFlake.devShells.x86_64-linux;
    expected = true;
  };

  nixosModules = {
    "test: nixosModule has _class nixos" = {
      expr = nixosModulesFlake.nixosModules.example._class;
      expected = "nixos";
    };

    "test: nixosModule has correct _file" = {
      expr = nixosModulesFlake.nixosModules.example._file;
      expected = "/test/path/flake.nix#nixosModules.example";
    };

    "test: nixosModule evaluates correctly" = {
      expr = (lib.evalModules {
        class = "nixos";
        modules = [
          nixosModulesFlake.nixosModules.example
        ];
      }).config.test.option;
      expected = "nixos-test";
    };
  };

  dogfood = {
    "test: importAndPublish provider" = {
      expr = dogfoodProvider.marker;
      expected = "dogfood";
    };

    "test: importAndPublish consumer" = {
      expr = dogfoodConsumer.marker;
      expected = "dogfood";
    };
  };

  touchup = {
    "test: any filter keeps only matching attrs" = {
      expr =
        let
          result = mkFlake { inputs.self = { }; } {
            imports = [ flake-parts.flakeModules.touchup ];
            systems = [ "x86_64-linux" "aarch64-darwin" ];
            touchup.any = { attrName, ... }: { enable = attrName == "overlays"; };
            perSystem = { ... }: {
              packages.default = throw "packages.default should not be evaluated";
              packages.hello = throw "packages.hello should not be evaluated";
            };
          };
        in
        result;
      expected = {
        overlays = { };
      };
    };

    "test: any with mkDefault, attr override" = {
      expr =
        let
          result = mkFlake { inputs.self = { }; } {
            imports = [ flake-parts.flakeModules.touchup ];
            systems = [ "x86_64-linux" "aarch64-darwin" ];
            touchup.any = { ... }: { enable = lib.mkDefault false; };
            touchup.attr.overlays = { enable = true; };
            perSystem = { ... }: {
              packages.default = throw "packages.default should not be evaluated";
              packages.hello = throw "packages.hello should not be evaluated";
            };
          };
        in
        result;
      expected = {
        overlays = { };
      };
    };

    "test: nested attr filtering per system" = {
      expr =
        let
          result = mkFlake { inputs.self = { }; } {
            imports = [ flake-parts.flakeModules.touchup ];
            systems = [ "x86_64-linux" "aarch64-darwin" ];
            touchup.attr.packages.attr.aarch64-darwin.attr.bar.enable = false;
            perSystem = { system, ... }: {
              packages.foo = pkg system "foo";
              # This assertion proves the filtered value is never evaluated for darwin
              packages.bar = assert system == "x86_64-linux"; pkg system "bar";
            };
          };
        in
        canon result.packages;
      expected = canon {
        aarch64-darwin = { foo = pkg "aarch64-darwin" "foo"; };
        x86_64-linux = { foo = pkg "x86_64-linux" "foo"; bar = pkg "x86_64-linux" "bar"; };
      };
    };

    "test: finish and attr composition" = {
      expr =
        mkFlake { inputs.self = { }; } {
          imports = [ flake-parts.flakeModules.touchup ];
          systems = [ "x86_64-linux" "aarch64-darwin" ];
          touchup.any = { ... }: { enable = lib.mkDefault false; };
          touchup.attr.overlays = { enable = true; finish = x: "hoi"; };
          touchup.finish = x: x // { foo = "bar"; };
        };
      expected = {
        overlays = "hoi";
        foo = "bar";
      };
    };

    # TODO: assert that the error context ("while touching up attribute 'broken'")
    # appears in the trace. nix-unit's expectedError.msg only matches the thrown
    # message, not addErrorContext frames.
    "test: error context when enabled attr throws" = {
      expr =
        let
          result = mkFlake { inputs.self = { }; } {
            imports = [ flake-parts.flakeModules.touchup ];
            systems = [ "x86_64-linux" ];
            flake.broken = throw "the value is broken";
          };
        in
        result.broken;
      expectedError.type = "ThrownError";
      expectedError.msg = "the value is broken";
    };
  };

  perInput = {
    "test: inputs' does not evaluate input flake formatter" =
      let
        inputFlake = {
          _type = "flake";
          outPath = "/fake";
          formatter = throw "must not evaluate input's formatter";
          packages.a.hello = pkg "a" "hello";
        };
        self = { _type = "flake"; outPath = "/test"; inputs = { inherit self; dep = inputFlake; }; };
        result = mkFlake
          { inputs = self.inputs; }
          {
            systems = [ "a" ];
            perSystem = { inputs', ... }: {
              packages.default = inputs'.dep.packages.hello;
            };
          };
      in
      {
        expr = (result.packages.a.default).name;
        expected = "hello";
      };
  };

  formatter = {
    "test: conditional null throws helpful error" = {
      expr =
        let
          result = mkFlake { inputs.self = { }; } {
            systems = [ "x86_64-linux" "aarch64-darwin" ];
            perSystem = { system, ... }: {
              formatter =
                if system == "x86_64-linux" then
                  derivation { name = "fmt"; builder = "x"; system = system; }
                else null;
            };
          };
        in
        result.formatter.aarch64-darwin;
      expectedError.type = "ThrownError";
      expectedError.msg = "could not determine statically(.|\n)*touchup\\.attr\\.formatter\\.enable = false";
    };

    "test: empty when never defined" = {
      expr =
        let
          result = mkFlake { inputs.self = { }; } {
            systems = [ "x86_64-linux" "aarch64-darwin" ];
            perSystem = { ... }: { };
          };
        in
        result.formatter == { };
      expected = true;
    };

    "test: present for all systems" = {
      expr =
        let
          result = mkFlake { inputs.self = { }; } {
            systems = [ "x86_64-linux" "aarch64-darwin" ];
            perSystem = { system, ... }: {
              formatter = derivation { name = "fmt"; builder = "x"; inherit system; };
            };
          };
        in
        result ? formatter && result.formatter ? x86_64-linux && result.formatter ? aarch64-darwin;
      expected = true;
    };

    "test: lazy per-system" = {
      expr =
        let
          result = mkFlake { inputs.self = { }; } {
            systems = [ "x86_64-linux" "aarch64-darwin" ];
            perSystem = { system, ... }: {
              formatter =
                if system == "x86_64-linux" then
                  derivation { name = "fmt"; builder = "x"; system = system; }
                else
                  throw "should not evaluate aarch64-darwin formatter";
            };
          };
        in
        result.formatter.x86_64-linux.name;
      expected = "fmt";
    };
  };
}
