
# Separate `tools` flake

Wouldn't recommend this pattern normally, but I'm trying to keep
deps low for `flake-modules-core` until we have split dev inputs
that don't carry over to dependent lock files.
