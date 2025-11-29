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
  name = "legacyPackages";
  option = mkOption {
    type = types.lazyAttrsOf types.raw;
    default = { };
    description = ''
      An attribute set of unmergeable values. This is also used by [`nix build .#<attrpath>`](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-build.html).

      `legacyPackages` supports nested attribute sets. Use `.` to access nested attributes:
      `.#foo.bar` refers to the `bar` attribute in `foo`.

      Attribute names that literally contain special characters like `.` must be doubly quoted when used in installable arguments:
      ```bash
      nix build '.#"example.com"'
      ```

      Consider using `:` or `/` as separators instead (e.g., `foo:bar`) for better command-line usability.
    '';
  };
  file = ./legacyPackages.nix;
}
