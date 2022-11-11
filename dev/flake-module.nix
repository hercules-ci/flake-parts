{ config, lib, inputs, withSystem, ... }:

{
  imports = [
    inputs.pre-commit-hooks-nix.flakeModule
    inputs.hercules-ci-effects.flakeModule
    ../site/flake-module.nix
  ];
  systems = [ "x86_64-linux" "aarch64-darwin" ];
  perSystem = { config, self', inputs', pkgs, ... }: {

    devShells.default = pkgs.mkShell {
      nativeBuildInputs = [
        pkgs.nixpkgs-fmt
        pkgs.pre-commit
        pkgs.hci
        pkgs.netlify-cli
        pkgs.pandoc
        pkgs.mdbook
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

  };
  herculesCI = herculesCI@{ config, ... }: {
    onPush.default.outputs = {
      effects =
        withSystem "x86_64-linux" ({ config, pkgs, hci-effects, ... }: {
          netlifyDeploy = hci-effects.netlifyDeploy {
            content = config.packages.siteContent;
            secretName = "default-netlify";
            siteId = "29a153b1-3698-433c-bc73-62415efb8117";
            productionDeployment = herculesCI.config.repo.branch == "main";
          };
        });
    };
  };
  flake = {
    # for repl exploration / debug
    config.config = config;
    options.mySystem = lib.mkOption { default = config.allSystems.${builtins.currentSystem}; };
  };
}
