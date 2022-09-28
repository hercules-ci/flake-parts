{ config, lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  inherit (flake-parts-lib)
    mkSubmoduleOptions
    ;
in
{
  options = {
    flake = mkSubmoduleOptions {
      overlays = mkOption {
        # uniq -> ordered: https://github.com/NixOS/nixpkgs/issues/147052
        # also update description when done
        type = types.nullOr (types.lazyAttrsOf (types.uniq (types.functionTo (types.functionTo (types.lazyAttrsOf types.unspecified)))));
        # This eta expansion exists for the sole purpose of making nix flake check happy.
        apply = x: if x == null
          then null
          else lib.mapAttrs (k: f: final: prev: f final prev) x;
        default = null;
        example = lib.literalExpression or lib.literalExample ''
          {
            default = final: prev: {};
          }
        '';
        description = ''
          An attribute set of overlays.

          Note that the overlays themselves are not mergeable. While overlays
          can be composed, the order of composition is significant, but the
          module system does not guarantee sufficiently deterministic
          definition ordering, across versions and when changing <literal>imports</literal>.
        '';
      };
    };
  };
}
