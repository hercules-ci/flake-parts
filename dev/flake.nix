{
  description = "Dependencies for development purposes";

  inputs = {
    # Flakes don't give us a good way to depend on .., so we don't.
    # This has drastic consequences of course.
    nixpkgs.url = "github:NixOS/nixpkgs";

    pre-commit-hooks-nix.url = "github:hercules-ci/pre-commit-hooks.nix/flakeModule";
    pre-commit-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";

    hercules-ci-effects.url = "github:hercules-ci/hercules-ci-effects";
  };

  outputs = { self, ... }:
    {
      # Without good or dev outputs, we only use flakes for inputs here.
      # The dev tooling is in ./flake-module.nix
    };
}
