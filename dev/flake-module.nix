{ config, inputs, lib, options, specialArgs, withSystem, ... } @ args:
let
  rootArgs = args;
  rootConfig = config;
  rootOptions = options;
  rootSpecialArgs = specialArgs;
in
# debugging tool
specialArgs.flakeModuleTransformer or (args: flakeModule: flakeModule) args {
  imports = [
    inputs.pre-commit-hooks-nix.flakeModule
    inputs.hercules-ci-effects.flakeModule # herculesCI attr
  ];
  config.systems = [ "x86_64-linux" "aarch64-darwin" ];

  config.hercules-ci.flake-update = {
    enable = true;
    autoMergeMethod = "merge";
    when.dayOfMonth = 1;
  };

  config.perSystem = { config, pkgs, ... }: {

    devShells.default = pkgs.mkShell {
      nativeBuildInputs = [
        pkgs.nixpkgs-fmt
        pkgs.pre-commit
        pkgs.hci
      ];
      shellHook = ''
        ${config.pre-commit.installationScript}
      '';
    };

    pre-commit = {
      inherit pkgs; # should make this default to the one it can get via follows
      settings = {
        hooks.nixpkgs-fmt.enable = true;
      };
    };

    checks.eval-tests =
      let tests = import ./tests/eval-tests.nix;
      in tests.runTests pkgs.emptyFile // { internals = tests; };

  };
  config.flake = { config, options, specialArgs, ... } @ args: {
    # for REPL exploration / debugging
    config.allFlakeModuleArgs = args // config._module.args // specialArgs;
    config.allRootModuleArgs = rootArgs // rootConfig._module.args // rootSpecialArgs;
    config.transformFlakeModule = flakeModuleTransformer:
      rootSpecialArgs.replaceSpecialArgs (prevSpecialArgs: prevSpecialArgs // {
        inherit flakeModuleTransformer;
      });
    options.mySystem = lib.mkOption {
      default = rootConfig.allSystems.${builtins.currentSystem};
    };
    config.effects = withSystem "x86_64-linux" ({ hci-effects, pkgs, ... }: {
      tests = {
        template = pkgs.callPackage ./tests/template.nix { inherit hci-effects; };
      };
    });
  };
}
