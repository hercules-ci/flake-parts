{
  description = "Dependencies for development purposes";

  inputs = {
    # Flakes don't give us a good way to depend on .., so we don't.
    # As a consequence, this flake is a little non-standard, and
    # we can't use the `nix` CLI as expected.

    nixpkgs.url = "github:NixOS/nixpkgs";
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    hercules-ci-effects.url = "github:hercules-ci/hercules-ci-effects";
  };

  outputs = { self, ... }:
    {
      # The dev tooling is in ./flake-module.nix
      # See comment at `inputs` above.
    };
}
