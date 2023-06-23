# shell-environment

> **Warning**
> If you copy the flake.nix remember to `git add [-N|--intent-to-add] flake.nix`, otherwise it won't work

This example shows how to create a shell environment which
includes a diverse set of tools:

```
terraform
wget
bat
git
```

You can search for more package in [nix packages](https://search.nixos.org/packages)

## Usage

The [`devShells` option](https://flake.parts/options/flake-parts.html#opt-perSystem.devShells) is used by the following command:

```sh
nix develop
```

You can have as many shells as you want, in this [flake.nix](./flake.nix), you also have
`another_env` which includes `curl`. To open it:

```sh
nix develop .#another_env
```