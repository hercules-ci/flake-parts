
# Running the tests

These tests can be run locally with the `hci effect run` command. This gives
the tests access to a proper nix daemon and the network.

Designed for convenient deployments, it needs some information from git. You
may use `--no-token` to disable this functionality if you're getting errors, or
if you're asked to log in.

Example:

```console
hci effect run --no-token default.effects.tests.template
```
