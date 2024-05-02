{ config, lib, inputs, withSystem, ... }:

{
  imports = [
    inputs.pre-commit-hooks-nix.flakeModule
    inputs.hercules-ci-effects.flakeModule # herculesCI attr
  ];
  systems = [ "x86_64-linux" "aarch64-darwin" ];

  hercules-ci.flake-update = {
    enable = true;
    autoMergeMethod = "merge";
    when.dayOfMonth = 1;
    flakes = {
      "." = { };
      "dev" = { };
    };
    effect.settings = {
      # Only fetch the `lib` subtree.
      # NOTE: Users don't have to do this. They are recommended to use follows
      #       and just use the `nixpkgs` they're already fetching anyway.
      #       It doesn't have to be `lib/` only!
      git.update.script = lib.mkBefore ''
        echo 'Fetching nixpkgs-lib tree'
        branch="nixos-unstable"
        mkdir ~/nixpkgs
        git -C ~/nixpkgs init
        git -C ~/nixpkgs remote add origin https://github.com/NixOS/nixpkgs.git
        git -C ~/nixpkgs fetch origin --filter=blob:none --depth=1 "$branch"
        commit="$(git -C ~/nixpkgs rev-parse FETCH_HEAD)"
        tree="$(git -C ~/nixpkgs rev-parse FETCH_HEAD:lib)"

        echo 'Adjusting nixpkgs-lib.url'
        sed -i flake.nix -e \
          's^    nixpkgs-lib\.url = ".*^    nixpkgs-lib\.url = "https://github.com/NixOS/nixpkgs/archive/'$tree'.tar.gz"; # '$commit' /lib from '$branch'^'
        git diff
        grep -F "$tree" flake.nix >/dev/null || {
          echo 'failed to write new tree to flake.nix'
          exit 1
        }
        git commit flake.nix -m 'flake.nix: Update nixpkgs-lib tree'
      '';
    };
  };

  perSystem = { config, pkgs, ... }: {

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
  flake = {
    # for repl exploration / debug
    config.config = config;
    options.mySystem = lib.mkOption { default = config.allSystems.${builtins.currentSystem}; };
    config.effects = withSystem "x86_64-linux" ({ pkgs, hci-effects, ... }: {
      tests = {
        template = pkgs.callPackage ./tests/template.nix { inherit hci-effects; };
      };
    });
  };
}
