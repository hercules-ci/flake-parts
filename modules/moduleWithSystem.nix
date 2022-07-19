{ config, lib, withSystem, ... }:
{
  config = {
    _module.args = {
      moduleWithSystem =
        module:

        { config, ... }:
        let
          system =
            config._module.args.system or
              config._module.args.pkgs.stdenv.hostPlatform.system or
                (throw "moduleWithSystem: Could not determine the configuration's system parameter for this module system application.");

          allArgs = withSystem system (args: args);

          lazyArgsPerParameter = f: builtins.mapAttrs
            (k: v: allArgs.${k} or (throw "moduleWithSystem: module argument `${k}` does not exist."))
            (builtins.functionArgs f);

          # Use reflection to make the call lazy in the argument.
          # Restricts args to the ones declared.
          callLazily = f: a: f (lazyArgsPerParameter f);
        in
        {
          imports = [
            (callLazily module allArgs)
          ];
        };
    };
  };
}
