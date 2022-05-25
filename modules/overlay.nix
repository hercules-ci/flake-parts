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
      overlay = mkOption {
        # uniq should be ordered: https://github.com/NixOS/nixpkgs/issues/147052
        # also update description when done
        type = types.uniq (types.functionTo (types.functionTo (types.lazyAttrsOf types.unspecified)));
        # This eta expansion exists for the sole purpose of making nix flake check happy.
        apply = f: final: prev: f final prev;
        default = _: _: { };
        defaultText = lib.literalExpression or lib.literalExample ''final: prev: {}'';
        description = ''
          An overlay.

          Note that this option's type is not mergeable. While overlays can be
          composed, the order of composition is significant, but the module
          system does not guarantee deterministic definition ordering.
        '';
      };
    };
  };
}
