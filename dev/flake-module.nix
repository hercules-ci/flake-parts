{ config, lib, inputs, ... }:

{
  imports = [
    inputs.pre-commit-hooks-nix.flakeModule
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
  flake = {
    options.herculesCI = lib.mkOption { type = lib.types.raw; };
    config.herculesCI = { branch, ... }: {
      onPush.default.outputs = {
        inherit (config.flake) packages checks;
        effects =
          let
            pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
            effects = inputs.hercules-ci-effects.lib.withPkgs pkgs;
          in
          {
            netlifyDeploy = effects.runIf (branch == "main") (effects.netlifyDeploy {
              content = config.flake.packages.x86_64-linux.siteContent;
              secretName = "default-netlify";
              siteId = "29a153b1-3698-433c-bc73-62415efb8117";
              productionDeployment = true;
            });
          };
      };
    };

    # for repl exploration / debug
    config.config = config;
    options.mySystem = lib.mkOption { default = config.allSystems.${builtins.currentSystem}; };
  };
}
