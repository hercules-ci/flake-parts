
# Flake Modules Core

_Core of a distributed framework for writing Nix Flakes._

`flake-modules-core` provides the options that represent standard flake attributes and establishes a way of working with `system`. Opinionated features are provided by an ecosystem of modules that you can import.

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

then slide `mkFlake` between your outputs function head and body,

```
  outputs = { self, flake-modules-core, ... }:
    flake-modules-core.lib.mkFlake { inherit self; } {
      flake = {
        # Put your original flake attributes here.
      }
    };
```

Now you can add the remaining module attributes like in the [the template](./template/default/flake.nix).

# Example

See [the template](./template/default/flake.nix).
