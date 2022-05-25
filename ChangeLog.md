
# 2022-05-25

 - `perSystem` is not a `functionTo submodule` anymore, but a `deferredModule`,
    which is a lot like a regular submodule, but possible to invoke multiple
    times, for each `system`.

    All `perSystem` value definitions must remove the `system: ` argument.
    If you need `system` to be in scope, use the one in the module arguments.

    ```diff
    -perSystem = system: { config, lib, ... }:
    +perSystem = { config, lib, system, ... }:
    ```

    All `perSystem` option declarations must now use `flake-parts-lib.mkPerSystemOption`.

    ```nix
    {
      options.perSystem = mkPerSystemOption ({ config, ... }: {
        options = {
          # ...
        };
        # ...
      });
    }
    ```

 - `flake-modules-core` is now called `flake-parts`.

 - `flake.overlay` has been removed in favor of `flake.overlays.default`.
