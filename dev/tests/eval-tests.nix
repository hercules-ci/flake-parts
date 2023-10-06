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

  exhibitingInfiniteRecursion = false;
  exhibitInfiniteRecursion = evalTests.extendEvalTests
    (finalEvalTest: prevEvalTests: { exhibitingInfiniteRecursion = true; });

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
  runEmptyTests = ok:
    assert evalTests.empty == evalTests.emptyResult;
    ok;
  emptyTestsResult = evalTests.runEmptyTests "ok";

  tooEmpty = evalTests.callFlake {
    inputs.flake-parts = evalTests.flake-parts;
    inputs.self = { };
    outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    };
  };
  # Shallow evaluation is successful…
  weakEvalTests.tooEmptyResultTried0.success = true;
  weakEvalTests.tooEmptyResultTried0.value = { };
  weakEvalTests.tooEmptyResultTried0TestTried.success = true;
  weakEvalTests.tooEmptyResultTried0TestTried.value = false;
  # …including for flake outputs…
  strongEvalTests.tooEmptyResultTried0 = evalTests.weakEvalTests.tooEmptyResultTried0;
  strongEvalTests.tooEmptyResultTried0TestTried = evalTests.weakEvalTests.tooEmptyResultTried0TestTried;
  # …but any evaluations of attribute values (flake output values) are not.
  weakEvalTests.tooEmptyResultTried1.success = true;
  weakEvalTests.tooEmptyResultTried1.value = {
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
  weakEvalTests.tooEmptyResultTried1TestTried.success = false;
  weakEvalTests.tooEmptyResultTried1TestTried.value = false;
  strongEvalTests.tooEmptyResultTried1.success = true;
  strongEvalTests.tooEmptyResultTried1.value = let
    _type = "flake";
    inputs.flake-parts = evalTests.flake-parts;
    inputs.self = { };
    outputs = evalTests.weakEvalTests.tooEmptyResultTried1.value;
    sourceInfo.outPath = "/unknown_eval-tests_flake";
    result = outputs // sourceInfo // { inherit _type inputs outputs sourceInfo; };
  in result;
  strongEvalTests.tooEmptyResultTried1TestTried.success = false;
  strongEvalTests.tooEmptyResultTried1TestTried.value = false;
  runTooEmptyTests = ok:
    let
      tooEmptyResultTried = builtins.tryEval evalTests.tooEmpty;
      tooEmptyResultTried0TestTried = builtins.tryEval (tooEmptyResultTried == evalTests.tooEmptyResultTried0);
      tooEmptyResultTried1TestTried = builtins.tryEval (tooEmptyResultTried == evalTests.tooEmptyResultTried1);
    in
    assert tooEmptyResultTried0TestTried == evalTests.tooEmptyResultTried0TestTried;
    assert tooEmptyResultTried1TestTried == evalTests.tooEmptyResultTried1TestTried;
    ok;
  tooEmptyTestsResult = evalTests.runTooEmptyTests "ok";

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
  runExample1Tests = ok:
    assert evalTests.example1 == evalTests.example1Result;
    ok;
  example1TestsResult = evalTests.runExample1Tests "ok";

  # This test case is a fun one. In the REPL, try `exhibitInfiniteRecursion.*`.
  # In the case that `mkFlake` *isn't* called from a flake, `inputs.self` is
  # unlikely to refer to the result of the `mkFlake` evaluation. If
  # `inputs.self` isn't actually self-referential, evaluating attribute values
  # of `self` is not divergent. Evaluation of `self.outPath` is useful for
  # paths in documentation & error messages. However, if that evaluation occurs
  # in a `builtins.addErrorContext` message forced by an erroring `self`, both
  # `self` will never evaluate *and* `builtins.toString self.outPath` must
  # evaluate, causing Nix to instead throw an infinite recursion error. Even
  # just `inputs.self ? outPath` throws an infinite recursion error.
  # (`builtins.tryEval` can only catch errors created by `builtins.throw` or
  # `builtins.assert`, so evaluation is guarded with
  # `exhibitingInfiniteRecursion` here to keep `runTests` from diverging.)
  # In this particular case, `mkFlake` evaluates `self ? outPath` to know if the
  # default module location it provides should be generic or specific. As
  # explained, this evaluation is unsafe under an uncatchably divergent `self`.
  # Thus, `outPath` cannot be safely sourced from `self` at the top-level.
  #
  # When tests are exhibititing infinite recursion, the abnormally correct
  # `self` is provided.
  weakEvalTests.nonexistentOption = let result = evalTests.callFlake {
    inputs.flake-parts = evalTests.flake-parts;
    inputs.self = if !evalTests.exhibitingInfiniteRecursion then { } else result;
    outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      config.systems = [ ];
      config.nonexistentOption = null;
    };
  }; in result;
  # When using actual flakes, this test always diverges. Unless tests are
  # exhibiting infinite recursion, the flake is made equivalent to `empty`.
  strongEvalTests.nonexistentOption = evalTests.callFlake {
    inputs.flake-parts = evalTests.flake-parts;
    inputs.self = { };
    outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } ({
      config.systems = [ ];
    } // (if !evalTests.exhibitingInfiniteRecursion then { } else {
      config.nonexistentOption = null;
    }));
  };
  weakEvalTests.nonexistentOptionResultTried0.success = true;
  weakEvalTests.nonexistentOptionResultTried0.value = { };
  weakEvalTests.nonexistentOptionResultTried0TestTried.success = true;
  weakEvalTests.nonexistentOptionResultTried0TestTried.value = false;
  strongEvalTests.nonexistentOptionResultTried0 = evalTests.weakEvalTests.nonexistentOptionResultTried0;
  strongEvalTests.nonexistentOptionResultTried0TestTried = evalTests.weakEvalTests.nonexistentOptionResultTried0TestTried;
  runNonexistentOptionTests = ok:
    let
      nonexistentOptionResultTried = builtins.tryEval evalTests.nonexistentOption;
      nonexistentOptionResultTried0TestTried = builtins.tryEval (nonexistentOptionResultTried == evalTests.nonexistentOptionResultTried0);
    in
    assert nonexistentOptionResultTried0TestTried == evalTests.nonexistentOptionResultTried0TestTried;
    ok;
  nonexistentOptionTestsResult = evalTests.runNonexistentOptionTests "ok";

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
  runFlakeModulesImportTests = ok:
    assert evalTests.flakeModulesImport.test123 == "123test";
    ok;
  flakeModulesImportTestsResult = evalTests.runFlakeModulesImportTests "ok";

  flakeModulesDisable = evalTests.callFlake {
    inputs.flake-parts = evalTests.flake-parts;
    inputs.flakeModulesDeclare = evalTests.flakeModulesDeclare;
    inputs.self = { };
    outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.flakeModulesDeclare.flakeModules.default ];
      disabledModules = [ inputs.flakeModulesDeclare.flakeModules.extra ];
    };
  };
  runFlakeModulesDisableTests = ok:
    assert evalTests.flakeModulesDisable.test123 == "option123";
    ok;
  flakeModulesDisableTestsResult = evalTests.runFlakeModulesDisableTests "ok";

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

  tryEvalOutputs = outputs: builtins.seq (builtins.attrNames outputs) outputs;

  runTests = ok:

    assert evalTests.runEmptyTests true;

    assert evalTests.runTooEmptyTests true;

    assert evalTests.runExample1Tests true;

    assert evalTests.runNonexistentOptionTests true;

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

    assert evalTests.runFlakeModulesImportTests true;

    assert evalTests.runFlakeModulesDisableTests true;

    assert evalTests.packagesNonStrictInDevShells.packages.a.default == evalTests.pkg "a" "hello";

    ok;

  result = evalTests.runTests "ok";
})).withWeakEvalTests
