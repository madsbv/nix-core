---
name: nix
description: >
  Use Nix to run programs not already available in the environment.
  When an agent needs a tool that isn't installed, use `nix run nixpkgs#<app>`
  to run it without installing permanently.
---

# nix — Run ad-hoc programs with Nix

## Purpose

When you need a CLI tool that isn't available in the current environment,
use Nix to run it ephemerally. No install needed — the binary is fetched
from the Nix package cache and run immediately.

## Usage

```bash
nix run nixpkgs#<package-name> [-- <args>]

# Examples:
nix run nixpkgs#jq -- '.key' data.json
nix run nixpkgs#yq
nix run nixpkgs#gh -- issue list
nix run nixpkgs#kubectl -- get pods
nix run nixpkgs#fd -- . --extension md
nix run nixpkgs#ripgrep -- pattern .
```

## How It Works

- `nixpkgs#<name>` refers to a package in the nixpkgs repository
- The binary is downloaded to the Nix store (cached for reuse)
- After running, the binary stays cached but doesn't pollute `$PATH`
- Subsequent runs are instant (already cached)

## Finding Package Names

```bash
# Search nixpkgs for a package
nix search nixpkgs <query>

# Example
nix search nixpkgs yaml-processor
```

## When to Use

- Need a tool not in `$PATH` (e.g., `jq`, `yq`, `gh`, `kubectl`, `fd`)
- One-off commands where installing permanently is overkill
- Trying a tool before deciding to add it to the config
- When the agent's environment is minimal but Nix is available

