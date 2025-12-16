{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  inherit (flake-parts-lib)
    mkTransposedPerSystemModule
    ;
in
mkTransposedPerSystemModule {
  name = "packages";
  option = mkOption {
    type = types.lazyAttrsOf types.package;
    default = { };
    description = ''
      An attribute set of packages to be built by [`nix build`](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-build.html).

      `nix build .#<name>` will build `packages.<name>`.

      You can also build attributes of a package using `.` to access nested attributes:
      `.#foo.tests.simple` builds the `simple` attribute in `foo.tests`.
      This is a Nixpkgs convention (packages having "passthru" attributes like `tests`) which gets no special treatment in Flakes.

      Attribute names containing special characters like `.` must be doubly quoted when used in installable arguments:
      ```bash
      nix build '.#"example.com"'
      ```

      Consider using `:` or `/` as separators instead (e.g., `foo:bar`) for better command-line usability.
    '';
  };
  file = ./packages.nix;
}
