{ config, lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkOption
    types
    literalExpression
    ;
  inherit (flake-parts-lib)
    mkSubmoduleOptions
    ;
in
{
  options = {
    flake = mkSubmoduleOptions {
      nixosConfigurations = mkOption {
        type = types.lazyAttrsOf types.raw;
        default = { };
        description = ''
          Instantiated NixOS configurations. Used by `nixos-rebuild`.

          `nixosConfigurations` is for specific machines. If you want to expose
          reusable configurations, add them to [`nixosModules`](#opt-flake.nixosModules)
          in the form of modules (no `lib.nixosSystem`), so that you can reference
          them in this or another flake's `nixosConfigurations`.
        '';
        example = literalExpression ''
          {
            my-machine = inputs.nixpkgs.lib.nixosSystem {
              # system is not needed with freshly generated hardware-configuration.nix
              # system = "x86_64-linux";  # or set nixpkgs.hostPlatform in a module.
              modules = [
                ./my-machine/nixos-configuration.nix
                config.nixosModules.my-module
              ];
            };
          }
        '';
      };
    };
  };
}
