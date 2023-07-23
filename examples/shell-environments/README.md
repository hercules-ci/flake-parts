# shell-environment

> **Warning**
> If you copy the flake.nix remember to `git add [-N|--intent-to-add] flake.nix`, otherwise it won't work

This example shows how to create a shell environment which
includes a diverse set of tools:

```sh
terraform
wget
bat
nixpkgs-fmt
```

You can search for more packages in [nix packages](https://search.nixos.org/packages)

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

## Troubleshooting

### I get bash instead of my shell

`nix develop` was designed for Nixpkgs stdenv, which uses bash, so that you can troubleshoot a Nix build with it. If you use a different shell, you'll want to get just the variables instead.

There are 3 possible solutions:

First, using [direnv](https://direnv.net/) to manage your dev environments. See [direnv-guide](https://haskell.flake.page/direnv). This is the recommended approach.

Second is a simple-unreliable hack, which is adding a `shellHook` to `devShells`

```nix
devShells.default = pkgs.mkShell {
  shellHook = ''
    exec $SHELL
  '';
};
```

You might get a lot different issues, use it at your own risk.

Lastly, there's `nix print-dev-env` which returns the variables - in case you're feeling adventurous, because this is far from a complete solution. See `nix print-dev-env --help`.
