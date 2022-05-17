flakeModuleArgs@{ config, lib, inputs, ... }:

{
  imports = [
    inputs.pre-commit-hooks-nix.flakeModule
  ];
  systems = [ "x86_64-linux" "aarch64-darwin" ];
  perSystem = system: { config, self', inputs', pkgs, ... }: {
    _module.args.pkgs = inputs'.nixpkgs.legacyPackages;

    devShells.default = pkgs.mkShell {
      nativeBuildInputs = [
        pkgs.nixpkgs-fmt
        pkgs.pre-commit
      ];
      shellHook = ''
        ${config.pre-commit.installationScript}
      '';
    };
    pre-commit = {
      inherit pkgs; # should make this default to the one it can get via follows
      settings = {
      };
    };

    packages = {
      inherit (pkgs.nixosOptionsDoc { inherit (flakeModuleArgs) options; })
        optionsDocBook;
      optionsMarkdown = pkgs.runCommand "options-markdown"
        {
          inherit (config.packages) optionsDocBook;
          nativeBuildInputs = [ pkgs.pandoc ];
        } ''
        mkdir $out
        pandoc \
          --from docbook \
          --to markdown \
          --output $out/options.md \
          $optionsDocBook
      '';
    };
  };
  flake = {
    options.herculesCI = lib.mkOption { type = lib.types.raw; };
    config.herculesCI = {
      onPush.default.outputs = { 
        inherit (config.flake) packages checks;
      };
    };

    # for repl exploration / debug
    config.config = config;
    options.mySystem = lib.mkOption { default = config.allSystems.${builtins.currentSystem}; };
  };
}
