
# `system`

In Nix, "system" generally refers to the cpu-os string, such as `"x86_64-linux"`.

In Flakes specifically, these strings are used as attribute names, so that the
Nix CLI can find a derivation for the right platform.

Many things, such as packages, can exist on multiple systems. For these, use
the [`perSystem`](options/flake-parts.html#opt-perSystem) submodule.

Other things do not exist on multiple systems. Examples are the configuration
of a specific machine, or a the execution of a deployment. These are not
written in `perSystem`, but in other top-level options, or directly into the
flake outputs' top level (e.g. [`flake.nixosConfigurations`](options/flake-parts.html#opt-flake.nixosConfigurations)).

Such top-level entities typically do need to read packages, etc that are defined
in `perSystem`. Instead of reading them from `config.flake.packages.<system>.<name>`,
it may be more convenient to bring all `perSystem` definitions for a system into
scope, using [`withSystem`](module-arguments.html#withsystem).
