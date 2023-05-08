{ config, flake-parts-lib, lib, ... }:
let
  inherit (flake-parts-lib)
    mkPerSystemOption
    ;
in
{
  options = {
    lint = {
      messages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Diagnostic messages that a flake author may or may not care about.

          For example, a module might detect that it's used in a weird way, but
          not be sure whether that's a mistake or not. Emitting a warning would
          be too much, but with this option, the author can still find the
          detected problem, by enabling [`debug`](#opt-debug) and querying
          the `debug.lint.messages` flake attribute in `nix repl`.

          This feature is not gated by an enable option, as performance does not
          suffer from an unevaluated option.

          There's also no option to upgrade to warnings, because that would make
          evaluation dependent on rather many options, even if the caller only
          needs one specific unrelated thing from the flake.
          A more complex interface could attach the warnings to specific flake
          attribute paths, but that's not implemented for now.
        '';
      };
    };
    perSystem = mkPerSystemOption
      ({ ... }: {
        options.lint.messages = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            Diagnostic messages that a flake author may or may not care about.

            These messages are added to the `debug.lint.messages` flake attribute,
            when [`debug`](#opt-debug) is enabled.
          '';
        };
      });
  };
  config = {
    extraDebug.lint.toplevel.messages = config.lint.messages;
    extraDebug.lint.messages =
      config.lint.messages ++
      lib.concatLists (
        lib.mapAttrsToList
          (sysName: sys:
            map
              (msg: "in perSystem.${sysName}: ${msg}")
              sys.lint.messages
          )
          config.allSystems
      );
  };
}
