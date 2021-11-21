{ config, lib, self, ... }:
let
  inherit (lib)
    mapAttrs
    mkOption
    types
    ;

  rootConfig = config;

in
{
  options = {
    systems = mkOption {
      description = "All the system types to enumerate in the flake.";
      type = types.listOf types.str;
    };

    perInput = mkOption {
      description = "Function from system to function from flake to system-specific attributes.";
      type = types.functionTo (types.functionTo (types.lazyAttrsOf types.unspecified));
    };

    perSystem = mkOption {
      description = "A function from system to flake-like attributes omitting the <system> attribute.";
      type = types.functionTo (types.submoduleWith {
        modules = [
          ({ config, system, ... }: {
            _file = ./perSystem.nix;
            config = {
              _module.args.inputs' = mapAttrs (k: rootConfig.perInput system) self.inputs;
              _module.args.self' = rootConfig.perInput system self;
            };
          })
        ];
        shorthandOnlyDefinesConfig = false;
      });
    };
  };

  config.perSystem = system: { _module.args.system = system; };
}
