{ config, flake-parts-lib, lib, options, getSystem, extendModules, ... }:
let
  inherit (lib)
    mapAttrs
    mkIf
    mkOption
    optionalAttrs
    types
    ;
  inherit (flake-parts-lib)
    mkPerSystemOption
    ;
  inherit (builtins)
    removeAttrs
    ;

  mkDebugConfig = { config, options, extendModules }: config // {
    inherit config;
    inherit (config) _module;
    inherit options;
    inherit extendModules;
  };
in
{
  options = {
    debug = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to add the attributes `debug`, `allSystems` and `currentSystem`
        to the flake output. When `true`, this allows inspection of options via
        `nix repl`.

        ```
        $ nix repl
        nix-repl> :lf .
        nix-repl> currentSystem._module.args.pkgs.hello
        «derivation /nix/store/7vf0d0j7majv1ch1xymdylyql80cn5fp-hello-2.12.1.drv»
        ```

        Each of `debug`, `allSystems.<system>` and `currentSystem` is an
        attribute set consisting of the `config` attributes, plus the extra
        attributes `_module`, `config`, `options`, `extendModules`. So note that
        these are not part of the `config` parameter, but are merged in for
        debugging convenience.

         - `debug`: The top-level options
         - `allSystems`: The `perSystem` submodule applied to the configured `systems`.
         - `currentSystem`: Shortcut into `allSystems`. Only available in impure mode.
           Works for arbitrary system values.

        See [Expore and debug option values](../debug.html) for more examples.
      '';
    };
    perSystem = mkPerSystemOption
      ({ options, config, extendModules, ... }: {
        _file = ./formatter.nix;
        options = {
          debug = mkOption {
            description = ''
              Values to return in e.g. `allSystems.<system>` when
              [`debug = true`](#opt-debug).
            '';
            type = types.lazyAttrsOf types.raw;
          };
        };
        config = {
          debug = mkDebugConfig { inherit config options extendModules; };
        };
      });
  };

  config = mkIf config.debug {
    flake = {
      debug = mkDebugConfig { inherit config options extendModules; };
      allSystems = mapAttrs (_s: c: c.debug) config.allSystems;
    } // optionalAttrs (builtins?currentSystem) {
      currentSystem = (getSystem builtins.currentSystem).debug;
    };
  };
}
