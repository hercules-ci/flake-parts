
# Flake Module Core

_Foundational flake attributes represented using the module system._

`flake-modules-core` provides common options for an ecosystem of modules to extend.

This allows anyone to bundle up tooling into reusable modules.

For users, this makes Flakes easier to wire up.

_Non-goals_:
 - Replace general Nix expressions, which are needed for advanced and/or ad-hoc use cases.
 - Accumulate everything into a single repository. As the name might suggest, it focuses only on options that have to do with well-known Nix Flakes attributes.


# Example Flake

```nix
{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-modules-core.url = "github:hercules-ci/flake-modules-core";
    flake-modules-core.inputs.nixpkgs.follows = "nixpkgs";
    devshell.url = "github:hercules-ci/devshell/flake-modules"; # credit to numtide
  };

  outputs = { self, nixpkgs, flake-modules-core, devshell, ... }:
    (flake-modules-core.lib.evalFlakeModule
      { inherit self; }
      {
        systems = [ "x86_64-linux" ];
        imports = [
          devshell.flakeModule
        ];
        flake = {
          nixosConfigurations.foo = lib.nixosSystem { /* ... */ };
        };
        perSystem = system: { config, pkgs, self', inputs', ... }: {
          _module.args.pkgs = inputs'.nixpkgs.legacyPackages;
          devshell.settings.commands = [
            {
              help = "format nix code";
              package = pkgs.nixpkgs-fmt;
            }
          ];
          packages.hello = pkgs.hello;
          packages.hello2 = self'.packages.hello;
          checks.hello = self'.packages.hello;
        };
      }).config.flake;

}
```
