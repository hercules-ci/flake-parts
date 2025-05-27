{ config, lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
in
{
  options = {
    touchup = mkOption {
      description = ''
        A set of modifications to apply to `processedFlake`.

        **Examples**:

        Only output explicitly listed flake output attributes:

        ```nix
        touchup = {
          any = {
            enable = lib.mkDefault false;
          };
          attr.packages.enable = true;
          attr.checks.enable = true;
        }
        ```

        Hide a package from users, but not from your own modules:

        ```nix
        touchup = {
          attr.packages.any.attr.hello.enable = false;
        };
        ```

        Hide a package on a set of systems:

        ```nix
        touchup = {
          attr.packages.any = { attrName, ... }: { attr.hello.enable = ! lib.strings.hasSuffix "-darwin" attrName; }
        };
        ```

      '';
      type = types.submoduleWith {
        modules = [ ./touchup/attrs.nix ];
      };
    };
  };
  config = {
    processedFlake = config.touchup.touchupApply config.flake;
  };
}
