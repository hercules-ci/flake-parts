{
  description = "Dependencies for development purposes";

  inputs = {
    # Flakes don't give us a good way to depend on .., so we don't.
    # As a consequence, this flake is a little non-standard, and
    # we can't use the `nix` CLI as expected.

    nixpkgs.url = "github:hercules-ci/nixpkgs/options-markdown-and-errors";

    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";

    hercules-ci-effects.url = "github:hercules-ci/hercules-ci-effects";

    haskell-flake.url = "github:srid/haskell-flake";
    haskell-flake.inputs.nixpkgs.follows = "nixpkgs";
    dream2nix.url = "github:nix-community/dream2nix";
    dream2nix.inputs.pre-commit-hooks.follows = "pre-commit-hooks-nix";
    dream2nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, ... }:
    {
      # The dev tooling is in ./flake-module.nix
      # See comment at `inputs` above.
    };
}
