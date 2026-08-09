# AGENTS.md

Guidelines for AI agents working in this repository.

## Committing

- Commit in **logical units** of work, each with a **conventional commit** message
  (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, ...) describing the change and, when
  useful, a short body explaining the rationale.
- Do not lump unrelated changes into one commit.
- Stage explicitly (`git add <paths>`) and commit the index; avoid `git commit -- <paths>`
  (it also sweeps in anything already staged).

## Formatting

- **Always run `nix fmt` before `nix flake check`.** The treefmt check derivation is
  part of `nix flake check`, and unformatted files will cause it to fail.
- `nix fmt` works in every repo — treefmt is propagated to leaf flakes through
  `core.flakeModules.default`.
- **The treefmt eval cache is disabled globally** (via `TREEFMT_NO_CACHE=1` in the
  formatter wrapper). This prevents the cache from silently skipping files that the
  sandboxed `nix flake check` (which always runs `treefmt --no-cache`) would detect.
- Formatting workflow after making changes:
  1. `nix fmt`
  2. `nix flake check`
  3. If both pass, stage and commit.

## Commit ordering across the fleet

This repo is the **shared core** and a path flake input of the `personal` and `work`
leaves. Leaves lock core by narHash derived from core's git state, so **core must be
committed before the leaves**. After a core commit, each leaf runs `nix flake update core`
and verifies its builds before committing its own changes.

## Porting from /etc/nixos/nix

When porting functionality from the old `/etc/nixos/nix` configuration:

- Improve code quality and organization; do not port the existing config verbatim.
- The purpose of the port is better architecture and wiring — `mine.*` options in place of
  `local.*` / `flake-root` / `specialArgs` / presets — while **retaining the end-user
  functionality** of the configuration.
- Port in smaller, semantically-portable units (one module or feature at a time), each
  verified to build, rather than mechanical file copies.
- Personal values and secrets stay out of core.
