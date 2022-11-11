
# Module Arguments

The module system allows modules and submodules to be defined using plain
attribute sets, or functions that return attribute sets. When a module is a
function, various attributes may be passed to it.

# Top-level Module Arguments

Top-level refers to the module passed to `mkFlake`, or any of the modules
imported into it using `imports`.

The standard module system arguments are available in all modules and submodules. These are chiefly `config`, `options`, `lib`.

## `getSystem`

A function from [system](./system.md) string to the `config` of the appropriate `perSystem`.

## `moduleWithSystem`

A function that brings the `perSystem` module arguments.
This allows a module to reference the defining flake without introducing
global variables.

```nix
{ moduleWithSystem, ... }:
{
  nixosModules.default = moduleWithSystem (
    perSystem@{ config }:  # NOTE: only explicit params will be in perSystem
    nixos@{ ... }:
    {
      services.foo.package = perSystem.config.packages.foo;
      imports = [ ./nixos-foo.nix ];
    }
  );
}
```

## `withSystem`

Enter the scope of a system. Worked example:

```nix
{ withSystem, ... }:
{
  # perSystem = ...;

  nixosConfigurations.foo = withSystem "x86_64-linux" (ctx@{ pkgs, ... }:
    pkgs.nixos ({ config, lib, packages, pkgs, ... }: {
      _module.args.packages = ctx.config.packages;
      imports = [ ./nixos-configuration.nix ];
      services.nginx.enable = true;
      environment.systemPackages = [
        packages.hello
      ];
    }));
}
```
