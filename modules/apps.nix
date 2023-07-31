{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkOption
    types
    getExe
    ;
  inherit (flake-parts-lib)
    mkTransposedPerSystemModule
    ;

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
