# FUP Migration — POC: Multi-Channel + Hosts + Registry in flake-parts

This example demonstrates how FUP's core features can be reimagined as
composable flake-parts modules. It's a proof-of-concept, not a library.

## Features demonstrated

| Feature | FUP's approach | flake-parts approach |
|---|---|---|
| **Multi-channel** | Implicit via `mkFlake` args | Declared via `fup.channels` option |
| **Overlay propagation** | `sharedOverlays` + per-channel `overlaysBuilder` | Same semantics, module-controlled |
| **Host abstraction** | `hosts.<name>` attrs in `mkFlake` | `fup.hosts` option; reverse-DNS naming |
| **Builder dispatch** | Auto-detects NixOS vs darwin | `output` field switches builder |
| **Channel patching** | `channels.<n>.patches` | Same via `fup.channels.<n>.patches` |
| **Auto-registry** | `nix.generateRegistryFromInputs` | `fup.autoRegistry` — generates NixOS module fragment |
| **Auto-nixPath** | `nix.generateNixPathFromInputs` | `fup.autoNixPath` — same technique |

## Key architectural difference

FUP uses a monolithic `mkFlake` function. This POC uses the flake-parts
**module system**: options are declared, config is computed, modules compose.

This avoids FUP's two worst architectural debts:
- **No double-eval hack**: FUP evaluates the entire NixOS config twice just to
  sniff `nixpkgs.config`. This module uses `getSystem` + perSystem evaluation
  — channel nixpkgs is evaluated once, hosts read the result.
- **No srcs side-channel**: FUP injects non-flake inputs into nixpkgs via an
  overlay. This module doesn't do that — inputs stay where they belong.

## What's left out vs FUP

- `outputsBuilder` — too coupled to FUP's per-system eval. flake-parts already
  has `perSystem.packages`, `perSystem.devShells`, etc.
- `exportModules` / `exportOverlays` / `exportPackages` — separate utilities,
  not shown here.
- `fup-repl` — would be a separate module.
- Channel auto-detection (`autoDetectChannels`) — included but opt-in.

## Files

| File | Purpose |
|---|---|
| `fup-module.nix` | The flake-parts module |
| `flake.nix` | Example flake that imports the module |

## Try it

```bash
nix flake show path:./examples/fup-migration
```
