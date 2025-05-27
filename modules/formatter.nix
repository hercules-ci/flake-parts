{ config, lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mapAttrs
    mkOption
    optionalAttrs
    types
    ;
  inherit (flake-parts-lib)
    mkSubmoduleOptions
    mkPerSystemOption
    ;

  # Do not copy this pattern! (probe, haveFormatterProbably, optionalAttrs)
  # It kind of works somewhat for `formatter`, but it is bad.
  # Nothing critical must rely on this!
  # - `tryEval` makes debugging harder and more annoying
  # - There's a performance cost to this otherwise useless evaluation
  # - We only use it *in `formatter`* because the effects are limited to that
  #   particular attribute. This makes the risk somewhat manageable.
  probe =
    config.perSystem
      # Elaborate error message that users should never see.
      # The reason to even do this, is that we can sidestep 
      # https://github.com/hercules-ci/flake-parts/issues/288 in many cases,
      # without flake author intervention to keep `nix flake check` happy.
      # When this solution fails.
      (throw ''
        For the purpose of finding out whether an option may be unset for all systems, flake-parts probes the perSystem module without a valid `system` argument, and tries to catch this exception if it finds that `system` is required for this determination. If you see this message, it means that for some reason, flake-parts was unable to catch this exception.

        This may be a bug in Nix or in flake-parts, but ultimately this is due to the quirky requirement of flakes that the "system" attribute does not come first.
        Flake-parts tries its best to correct that UX, but ultimately, this needs to be solved in Nix.
      '');

  haveFormatterProbably =
    let
      ev =
        builtins.tryEval
          probe.formatter;
    in
    # If it fails, we can't assume that we don't have a formatter, because it may well evaluate for a real system.
    !ev.success
    || ev.value != null;
in
{
  options = {
    flake = mkSubmoduleOptions {
      formatter = mkOption {
        type = types.lazyAttrsOf (types.nullOr types.package);
        default = { };
        description = ''
          An attribute set of per system a package used by [`nix fmt`](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-fmt.html).
        '';
      };
    };

    perSystem = mkPerSystemOption {
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
    };
  };
  config = {
    flake.formatter =
      # Work around `nix flake check` not allowing `null` values in output attributes.
      optionalAttrs
        haveFormatterProbably
        (mapAttrs
          (k: v:
            if v != null then v.formatter
            else
              throw ''
                flake-parts could not determine statically that no formatter is defined for *all* systems.

                What happened?

                1. For performance reasons, flake-parts must not query `perSystem` for every system, so it uses a heuristic to determine whether a formatter is defined for all systems.
                2. Unfortunately, this heuristic is not perfect, and it wasn't able to determine for your flake that `perSystem.formatter` is always `null` (if it even is always `null`).
                As a consequence of (1), flake-parts had to provide the output attribute `formatter.${k}`, but as a consequence of (2), you're seeing this error.

                What to do?

                This whole situation should be temporary. `nix flake check`/`show` can be changed to allow `null` values, which gives flake-parts and other frameworks a way to avoid this situation.

                To change the `formatter` output attribute, you can control it precisely with the `touchup` module, for example:

                    imports = [ inputs.flake-parts.flakeModules.touchup ];

                    # Remove it
                    touchup.attr.formatter.enable = false;

                    # ... or only have it for listed systems
                    touchup.attr.formatter.any.enable = lib.mkDefault false;
                    touchup.attr.formatter.attr.x86_64-linux.enable = true;
                    touchup.attr.formatter.attr.aarch64-darwin.enable = true;

              '')
          config.allSystems);

    perInput = system: flake:
      optionalAttrs (flake?formatter.${system}) {
        formatter = flake.formatter.${system};
      };

  };
}
