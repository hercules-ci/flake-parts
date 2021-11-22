
# Flake Module Core

_Foundational flake attributes represented using the module system._

`flake-modules-core` provides common options for an ecosystem of modules to extend.

# Why Modules?

Flakes are configuration. The module system lets you refactor configuration
into modules that can be shared.

It reduces the proliferation of custom Nix glue code, similar to what the
module system has done for NixOS configurations.

Unlike NixOS, but following Flakes' spirit, `flake-modules-core` is not a
monorepo with the implied goal of absorbing all of open source, but rather
a single module that other repositories can build upon, while ensuring a
baseline level of compatibility: which core attribute make up a flake and
how these are represented as module options.

# Getting Started

If your project does not have a flake yet:

```console
nix flake init -t github:hercules-ci/flake-modules-core
```

Otherwise, add the input,

```
    flake-modules-core.url = "github:hercules-ci/flake-modules-core";
    flake-modules-core.inputs.nixpkgs.follows = "nixpkgs";
```

then slide `evalFlakeModule` between your outputs function head and body,

```
  outputs = { self, flake-modules-core, ... }:
    (flake-modules-core.lib.evalFlakeModule
      { inherit self; }
      {
        flake = {
          # Put your original flake attributes here.
        }
      }
    ).config.flake;
```

Now you can add the remaining module attributes like in the [the template](./template/flake.nix).

# Example

See [the template](./template/flake.nix).
