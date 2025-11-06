# `vendor/flake-compat`

Flake-parts uses [flake-compat] in the partitions module.

Revision: f387cd2afec9419c8ee37694406ca490c3f34ee5

Non-essential files were omitted: `flake.nix`, CI configuration.

## Why vendor?

Vendoring is generally not recommended, but for flake-parts we make a different trade-off.

- Dependency is tiny
- Fetching latency is significant compared to size
- Cost gets multiplied by the high number of users/callers and flake-parts occurrences (when follows isn't used)
- Some users care about the size of their lock file
- Nix has some overhead for each lock node when updating a lock file
- Hard to provide input in the Nix sandbox (for those who have evaluation tests in derivations)
- Most users are unaffected (only impacts users of `partitions`)

[flake-compat]: https://github.com/NixOS/flake-compat
