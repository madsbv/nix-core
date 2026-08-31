# AGENTS.md

Guidelines for AI agents working in this Nix fleet. This file is the shared reference
for all three repos (`core`, `personal`, `work`).

## Repo map

- `core/` (this repo) — shared framework: flake-parts modules, `mine.*` options, host builders. No hosts, identity, or secrets.
- `personal/` — NixOS + nix-darwin personal hosts and secrets.
- `work/` — work laptop (Home Manager standalone today, nixos-wsl planned). Must never reference `personal/`.

Each repo is its own git repository — run `git` / `nix` / `just` from inside the repo you're changing, not the parent directory.

## Committing

- Commit in **logical units**, each with a **conventional commit** message (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, ...) and, when useful, a short body explaining the rationale.
- Do not lump unrelated changes into one commit.
- Stage explicitly (`git add <paths>`) and commit the index; avoid `git commit -- <paths>` (it also sweeps in anything already staged).

## Formatting

- **Always run `nix fmt` before `nix flake check`.** The treefmt check derivation is part of `nix flake check`, and unformatted files cause it to fail.
- `nix fmt` works in every repo — treefmt is propagated to leaf flakes through `core.flakeModules.default`.
- **The treefmt eval cache is disabled globally** (`TREEFMT_NO_CACHE=1` in the formatter wrapper), so it won't silently skip files the sandboxed `nix flake check` (which runs `treefmt --no-cache`) would detect.
- After making changes: `nix fmt` → `nix flake check` → stage and commit.

## Commit ordering across the fleet

`personal` and `work` are leaves; their only upstream input is `core`, pinned as a **`github:` input** (`github:madsbv/nix-core` in each leaf `flake.nix`).

- **Commit and push `core` first** — leaves lock core by git rev from GitHub.
- Then in each leaf run `nix flake update core`, verify it still builds (`nix flake check`, host builds), and commit.
- Dev-loop against uncommitted core changes: `--override-input core path:../core`.

## Pushing & session workflow

- **Never push to `origin` unless explicitly instructed.** Commit locally and ask before pushing.
- During a session, test against uncommitted core changes with `--override-input core path:../core` rather than relocking.
- At the end of an implementation session, ask whether to push `core`, then relock (`nix flake update core`) and push the leaves.

## Porting from /etc/nixos/nix

- Improve code quality and organization; do not port the existing config verbatim.
- The goal is better architecture and wiring — `mine.*` options in place of `local.*` / `flake-root` / `specialArgs` / presets — while **retaining the end-user functionality**.
- Port in smaller, semantically-portable units (one module or feature at a time), each verified to build.
- Personal values and secrets stay out of `core`.

## Commands

- Verify core: `nix flake check` (works without secrets)
- Build/switch a personal host: `just build [host=...]` / `just switch` (from `personal/`)
- `just deploy`, `just rekey`, `just edit-secret` require the YubiKey; checks and builds work without it (committed `rekeyed/`).
