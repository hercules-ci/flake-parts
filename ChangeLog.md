
# 2022-11-27

 - The `darwinModules` option has been removed. This was added in the early days
   without full consideration. The removal will have no effect on most flakes
   considering that the [`flake` option](https://flake.parts/options/flake-parts.html#opt-flake)
   allows any attribute to be set. This attribute and related attributes should
   be added to the nix-darwin project instead.

# 2022-10-11

 - The `nixpkgs` input has been renamed to `nixpkgs-lib` to signify that the
   only dependency is on the `lib` attribute, which can be provided by either
   the `nixpkgs?dir=lib` subflake or by the `nixpkgs` flake itself.
   
 - The templates now use the default, _fixed_ `nixpkgs?dir=lib` dependency instead
   of a _following_ `nixpkgs` dependency.

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
