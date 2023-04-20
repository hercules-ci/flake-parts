# Run with
#
#     nix build -f dev checks.x86_64-linux.eval-tests

let
  flake-parts = builtins.getFlake (toString ../..);
  lib = flake-parts.inputs.nixpkgs-lib.lib;
in
(lib.makeExtensibleWithCustomName "extendEvalTests" (evalTests: {
  inherit evalTests;
  inherit flake-parts;
  flake-parts-lib = evalTests.flake-parts.lib;
  inherit lib;

  devFlake = builtins.getFlake (toString ../.);
  nixpkgs = evalTests.devFlake.inputs.nixpkgs;

  inherit (evalTests.flake-parts-lib) mkFlake;
  weakEvalTests.callFlake = { ... } @ flake:
    let
      sourceInfo = flake.sourceInfo or { };
      inputs = flake.inputs or { };
      outputs = flake.outputs inputs;
      result = outputs;
    in
    result;
  strongEvalTests.callFlake = { ... } @ flake:
    let
      sourceInfo = { outPath = "/unknown_eval-tests_flake"; } //
        flake.sourceInfo or { };
      inputs = flake.inputs or { };
      outputs = flake.outputs (inputs // { self = result; });
      result = outputs // sourceInfo // {
        inherit inputs outputs sourceInfo;
        _type = "flake";
      };
    in
    assert builtins.isFunction flake.outputs;
    result;

  withWeakEvalTests = evalTests.extendEvalTests (finalEvalTests: prevEvalTests:
    builtins.mapAttrs (name: value: finalEvalTests.weakEvalTests.${name})
      prevEvalTests.weakEvalTests
  );
  withStrongEvalTests = evalTests.extendEvalTests (finalEvalTests: prevEvalTests:
    builtins.mapAttrs (name: value: finalEvalTests.strongEvalTests.${name})
      prevEvalTests.strongEvalTests
  );

  pkg = system: name: derivation {
    name = name;
    builder = "no-builder";
    system = system;
  };

  empty = evalTests.callFlake {
    inputs.flake-parts = evalTests.flake-parts;
    inputs.self = { };
    outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ ];
    };
  };
  weakEvalTests.emptyResult = {
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
  strongEvalTests.emptyResult = let
    _type = "flake";
    inputs.flake-parts = evalTests.flake-parts;
    inputs.self = { };
    outputs = evalTests.weakEvalTests.emptyResult;
    sourceInfo.outPath = "/unknown_eval-tests_flake";
    result = outputs // sourceInfo // { inherit _type inputs outputs sourceInfo; };
  in result;

  example1 = evalTests.callFlake {
    inputs.flake-parts = evalTests.flake-parts;
    inputs.self = { };
    outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "a" "b" ];
      perSystem = { system, ... }: {
        packages.hello = evalTests.pkg system "hello";
      };
    };
  };
  weakEvalTests.example1Result = {
    apps = { a = { }; b = { }; };
    checks = { a = { }; b = { }; };
    devShells = { a = { }; b = { }; };
    formatter = { };
    legacyPackages = { a = { }; b = { }; };
    nixosConfigurations = { };
    nixosModules = { };
    overlays = { };
    packages = {
      a = { hello = evalTests.pkg "a" "hello"; };
      b = { hello = evalTests.pkg "b" "hello"; };
    };
  };
  strongEvalTests.example1Result = let
    _type = "flake";
    inputs.flake-parts = evalTests.flake-parts;
    inputs.self = { };
    outputs = evalTests.weakEvalTests.example1Result;
    sourceInfo.outPath = "/unknown_eval-tests_flake";
    result = outputs // sourceInfo // { inherit _type inputs outputs sourceInfo; };
  in result;

  packagesNonStrictInDevShells = evalTests.callFlake {
    inputs.flake-parts = evalTests.flake-parts;
    # approximation
    inputs.self = evalTests.packagesNonStrictInDevShells;
    outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "a" "b" ];
      perSystem = { self', system, ... }: {
        packages.hello = evalTests.pkg system "hello";
        packages.default = self'.packages.hello;
        devShells = throw "can't be strict in perSystem.devShells!";
      };
      flake.devShells = throw "can't be strict in devShells!";
    };

  easyOverlay = evalTests.callFlake {
    inputs.flake-parts = evalTests.flake-parts;
    inputs.self = { };
    outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.flake-parts.flakeModules.easyOverlay ];
      systems = [ "a" "aarch64-linux" ];
      perSystem = { system, config, final, pkgs, ... }: {
        packages.default = config.packages.hello;
        packages.hello = evalTests.pkg system "hello";
        packages.hello_new = final.hello;
        overlayAttrs = {
          hello = config.packages.hello;
          hello_old = pkgs.hello;
          hello_new = config.packages.hello_new;
        };
      };
    };
  };

  flakeModulesDeclare = evalTests.callFlake {
    inputs.flake-parts = evalTests.flake-parts;
    inputs.self = { outPath = ./.; };
    outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } ({ config, inputs, lib, ... }: {
      imports = [ inputs.flake-parts.flakeModules.flakeModules ];
      systems = [ ];
      flake.flakeModules.default = { lib, ... }: {
        options.flake.test123 = lib.mkOption { default = "option123"; };
        imports = [ config.flake.flakeModules.extra ];
      };
      flake.flakeModules.extra = {
        flake.test123 = "123test";
      };
    });
  };

  flakeModulesImport = evalTests.callFlake {
    inputs.flake-parts = evalTests.flake-parts;
    inputs.flakeModulesDeclare = evalTests.flakeModulesDeclare;
    inputs.self = { };
    outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.flakeModulesDeclare.flakeModules.default ];
    };
  };

  flakeModulesDisable = evalTests.callFlake {
    inputs.flake-parts = evalTests.flake-parts;
    inputs.flakeModulesDeclare = evalTests.flakeModulesDeclare;
    inputs.self = { };
    outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.flakeModulesDeclare.flakeModules.default ];
      disabledModules = [ inputs.flakeModulesDeclare.flakeModules.extra ];
    };
  };

  nixpkgsWithoutEasyOverlay = import evalTests.nixpkgs {
    system = "x86_64-linux";
    overlays = [ ];
    config = { };
  };

  nixpkgsWithEasyOverlay = import evalTests.nixpkgs {
    # non-memoized
    system = "x86_64-linux";
    overlays = [ evalTests.easyOverlay.overlays.default ];
    config = { };
  };

  nixpkgsWithEasyOverlayMemoized = import evalTests.nixpkgs {
    # memoized
    system = "aarch64-linux";
    overlays = [ evalTests.easyOverlay.overlays.default ];
    config = { };
  };

  runTests = ok:

    assert evalTests.empty == evalTests.emptyResult;

    assert evalTests.example1 == evalTests.example1Result;

    # - exported package becomes part of overlay.
    # - perSystem is invoked for the right system, when system is non-memoized
    assert evalTests.nixpkgsWithEasyOverlay.hello == evalTests.pkg "x86_64-linux" "hello";

    # - perSystem is invoked for the right system, when system is memoized
    assert evalTests.nixpkgsWithEasyOverlayMemoized.hello == evalTests.pkg "aarch64-linux" "hello";

    # - Non-exported package does not become part of overlay.
    assert evalTests.nixpkgsWithEasyOverlay.default or null != evalTests.pkg "x86_64-linux" "hello";

    # - hello_old comes from super
    assert evalTests.nixpkgsWithEasyOverlay.hello_old == evalTests.nixpkgsWithoutEasyOverlay.hello;

    # - `hello_new` shows that the `final` wiring works
    assert evalTests.nixpkgsWithEasyOverlay.hello_new == evalTests.nixpkgsWithEasyOverlay.hello;

    assert evalTests.flakeModulesImport.test123 == "123test";

    assert evalTests.flakeModulesDisable.test123 == "option123";

    assert evalTests.packagesNonStrictInDevShells.packages.a.default == evalTests.pkg "a" "hello";

    ok;

  result = evalTests.runTests "ok";
})).withWeakEvalTests
