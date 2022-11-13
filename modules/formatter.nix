{ config, lib, flake-parts-lib, ... }:
let
  inherit (lib)
    filterAttrs
    mapAttrs
    mkOption
    optionalAttrs
    types
    ;
  inherit (flake-parts-lib)
    mkSubmoduleOptions
    mkPerSystemOption
    ;
in
{
  options = {
    flake = mkSubmoduleOptions {
      formatter = mkOption {
        type = types.lazyAttrsOf types.package;
        default = { };
        description = ''
          An attribute set of per system a package used by [`nix fmt`](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-fmt.html).
        '';
      };
    };

    perSystem = mkPerSystemOption ({ config, ... }: {
      _file = ./formatter.nix;
      options = {
        formatter = mkOption {
          type = types.nullOr types.package;
          default = null;
          description = ''
            A package used by [`nix fmt`](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-fmt.html).
          '';
        };
      };
    });
  };
  config = {
    flake.formatter =
      mapAttrs
        (k: v: v.formatter)
        (filterAttrs
          (k: v: v.formatter != null)
          config.allSystems
        );

    perInput = system: flake:
      optionalAttrs (flake?formatter.${system}) {
        formatter = flake.formatter.${system};
      };

  };
}
