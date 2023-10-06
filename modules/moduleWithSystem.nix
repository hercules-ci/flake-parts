{ withSystem, ... }:
{
  config = {
    _module.args = {
      moduleWithSystem =
        module:

        { config, ... }:
        let
          system =
            config._module.args.system or
              config._module.args.pkgs.stdenv.hostPlatform.system or (throw
                "moduleWithSystem: Could not determine the `system` parameter for this module set evaluation."
              );

          allPerSystemArgs = withSystem system (args: args);

          lazyPerSystemArgsPerParameter = f: builtins.mapAttrs
            (k: v: allPerSystemArgs.${k} or (throw "moduleWithSystem: per-system argument `${k}` does not exist."))
            (builtins.functionArgs f);

          # Use reflection to make the call lazy in the argument.
          # Restricts args to the ones declared.
          callLazily = f: a: f (lazyPerSystemArgsPerParameter f);
        in
        {
          imports = [
            (callLazily module allPerSystemArgs)
          ];
        };
    };
  };
}
