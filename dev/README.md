# Separate `dev` flake

Wouldn't recommend this pattern normally, but I'm trying to keep
deps low for `flake-parts` until we have split dev inputs
that don't carry over to dependent lock files.

```sh
nix develop --impure -f './dev' 'mySystem.devShells.default'
nix repl -f './dev'
```
