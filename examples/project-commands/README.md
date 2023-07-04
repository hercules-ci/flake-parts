# project-commands

> **Warning**
> If you copy the flake.nix remember to `git add [-N|--intent-to-add] flake.nix`, otherwise it won't work

This example shows how to create scripts for your project, by leveraging [mission-control](https://github.com/Platonic-Systems/mission-control)

This is a **potential** alternative to:

- Using a `Makefile` to manage your project's scripts
- Using the popular [Scripts To Rule Them All](https://github.com/github/scripts-to-rule-them-all); a naming convention for a `scripts/` directory
- Using a `bin/` directory

## Explanation

In this example we use the [avro-tools](https://avro.apache.org/) to convert our scripts from `.avdl` to `.avsc`.

You don't need to know anything about avro to understand mission-control and use this example (that's Nix baby 🚀).

When setting up [mission-control](https://github.com/Platonic-Systems/mission-control), we add
one script called `build`. Because of `wrapperName = "run";`, once we open the shell created by nix,
the commands will be listed as `run build`.

mission-control depends on flake-root, which also exposes the helpful `$FLAKE_ROOT` variable.

After creating the scripts, we need to pass the newly created scripts to the desired shell, in this example we use the default shell.

## Usage

Run:

```sh
nix develop
```

And mission-control will print in the new shell the available commands (you should see only one).

Try running

```sh
run build
```
