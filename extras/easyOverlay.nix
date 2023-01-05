toplevel@{ config, lib, flake-parts-lib, getSystemIgnoreWarning, ... }:
let
  inherit (flake-parts-lib)
    mkPerSystemOption;
  inherit (lib)
    mkOption
    types;
in
{
  options = {
    perSystem = mkPerSystemOption ({ config, extendModules, pkgs, ... }: {
      _file = ./easyOverlay.nix;
      options = {
        extendModules = mkOption {
          type = types.raw;
          default = extendModules;
          internal = true;
        };
        overlayAttrs = mkOption {
          type = types.lazyAttrsOf types.raw;
          default = { };
          description = ''
            Attributes to add to `overlays.default`.

            The `overlays.default` overlay will re-evaluate `perSystem` with
            the "prev" (or "super") overlay argument value as the `pkgs` module
            argument. The `easyOverlay` module also adds the `final` module
            argument, for the result of applying the overlay.

            When not in an overlay, `final` defaults to `pkgs` plus the generated
            overlay. This requires Nixpkgs to be re-evaluated, which is more
            expensive than setting `pkgs` to a Nixpkgs that already includes
            the necessary overlays that are required for the flake itself.

            See [Overlays](../overlays.html).
          '';
        };
      };
      config = {
        _module.args.final = lib.mkDefault (pkgs.extend (toplevel.config.flake.overlays.default));
      };
    });
  };
  config = {
    flake.overlays.default = final: prev:
      let
        system =
          prev.stdenv.hostPlatform.system or (
            prev.system or (
              throw "Could not determine the `hostPlatform` of Nixpkgs. Was this overlay loaded as a Nixpkgs overlay, or was it loaded into something else?"
            )
          );
        perSys = (getSystemIgnoreWarning system).extendModules {
          modules = [
            {
              _file = "flake-parts#flakeModules.easyOverlay/overlay-overrides";
              _module.args.pkgs = lib.mkForce prev;
              _module.args.final = lib.mkForce final;
            }
          ];
        };
      in
      perSys.config.overlayAttrs;
  };
}
