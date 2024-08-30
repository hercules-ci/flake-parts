{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  inherit (flake-parts-lib)
    mkTransposedPerSystemModule
    ;

  getExe = lib.getExe or (
    x:
    "${lib.getBin x}/bin/${x.meta.mainProgram or (throw ''Package ${x.name or ""} does not have meta.mainProgram set, so I don't know how to find the main executable. You can set meta.mainProgram, or pass the full path to executable, e.g. program = "''${pkg}/bin/foo"'')}"
  );

  programType = lib.types.coercedTo derivationType getExe lib.types.str;

  derivationType = lib.types.package // {
    check = lib.isDerivation;
  };

  appType = lib.types.submodule {
    options = {
      type = mkOption {
        type = lib.types.enum [ "app" ];
        default = "app";
        description = ''
          A type tag for `apps` consumers.
        '';
      };
      program = mkOption {
        type = programType;
        description = ''
          A path to an executable or a derivation with `meta.mainProgram`.
        '';
      };
      meta = mkOption {
        type = types.lazyAttrsOf lib.types.raw;
        default = { };
        # TODO refer to Nix manual 2.25
        description = ''
          Metadata information about the app.
          Standardized in Nix at <https://github.com/NixOS/nix/pull/11297>.

          Note: `nix flake check` is only aware of the `description` attribute in `meta`.
        '';
      };
    };
  };
in
mkTransposedPerSystemModule {
  name = "apps";
  option = mkOption {
    type = types.lazyAttrsOf appType;
    default = { };
    description = ''
      Programs runnable with nix run `<name>`.
    '';
    example = lib.literalExpression or lib.literalExample ''
      {
        default.program = "''${config.packages.hello}/bin/hello";
      }
    '';
  };
  file = ./apps.nix;
}
