{
  description = "Dependencies for development purposes";

  inputs = {
    # Flakes don't give us a good way to depend on .., so we don't.
    # As a consequence, this flake only provides dependencies, and
    # we can't use the `nix` CLI as expected.

    nixpkgs.url = "github:NixOS/nixpkgs";
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    hercules-ci-effects.url = "github:hercules-ci/hercules-ci-effects";
  };

  outputs = { ... }:
    {
      # The dev tooling is in ./flake-module.nix
      # See comment at `inputs` above.
      # It is loaded into partitions.dev by the root flake.
    };
}
