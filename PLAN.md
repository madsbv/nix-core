# Implementation Plan

Detailed, milestone-based plan for building the three-repo fleet described in [README.md](./README.md).
Status legend: `[ ]` todo · `[~]` in progress · `[x]` done.

---

## Milestone 0 — Bootstrap scaffolding

Goal: three valid, evaluable flakes in sibling directories with the right input topology, proving that
a leaf can consume `core` as an input.

- [ ] `core/flake.nix` declares all inputs (nixpkgs, flake-parts, home-manager, nix-darwin,
      agenix-rekey, nixos-wsl, deploy-rs), each following core's nixpkgs where applicable.
- [ ] `core/flake.lock` is generated (`nix flake lock`) so all inputs are pinned.
- [ ] `personal/flake.nix` and `work/flake.nix` declare only `core` (+ `nixpkgs.follows = "core/nixpkgs"`).
- [ ] Each directory is a git repo with a `.gitignore` (`/result`, `.direnv/`).
- [ ] `nix flake check` passes in `core`; `nix flake metadata` works in `personal` and `work`.

**Acceptance criteria**

- `nix flake show` in `core` shows a valid (if empty) flake.
- `nix flake metadata` in `personal`/`work` resolves `core` and shows `nixpkgs` following `core/nixpkgs`.

---

## Milestone 1 — Core module framework

Goal: the flake-parts + dendritic skeleton with identity options and auto-loading, plus a throwaway
leaf proving cross-repo consumption.

- [ ] Add `import-tree`-style auto-loader (files under `modules/` become flake-parts modules; files
      starting with `_` are treated as helpers and skipped).
- [ ] Declare the `mine.*` option namespace in `modules/options.nix` (no defaults):
      `mine.hostName`, `mine.user.{username,fullName,email}`, `mine.location.{timezone,latitude,longitude}`,
      `mine.network.tailscale.enable`.
- [ ] Add `modules/base.nix` composing `nixos.base` / `darwin.base` / `homeManager.base` (initial
      contents: imports of the options module + agenix wiring + minimal per-class base).
- [ ] Add two representative feature modules to prove the pattern:
      - `features/dev/git.nix` (homeManager; reads `config.mine.user.*`)
      - `features/shell.nix` (homeManager; zsh + starship + fzf/zoxide/eza/bat)
- [ ] Implement `lib/mkNixosHost.nix` (wires options + agenix + home-manager-as-module with
      `useGlobalPkgs`/`useUserPackages`, accepts `hostname`, `profiles`, `modules`, `identity`).
- [ ] Implement `lib/mkHomeConfig.nix` (standalone Home Manager; same HM modules + options module via
      `home-manager.sharedModules`).
- [ ] Implement `lib/mkDarwinHost.nix` (stub wiring; full contents in M4).
- [ ] Create a throwaway `personal` host (`hosts/scaffold-test/`) that sets `mine.*`, imports core
      profiles, and builds via `mkNixosHost`; plus a throwaway standalone HM config built via
      `mkHomeConfig`. Verify both evaluate.
- [ ] Add `lib/mkDeploy.nix` scaffolding (empty `deploy` output + `deployChecks`), wired into leaves.

**Acceptance criteria**

- A single core feature file produces a Home Manager module usable in both a NixOS-integrated HM and a
  standalone `homeConfigurations` build, reading the same `mine.*` values.
- `nix build .#nixosConfigurations.scaffold-test` (in the throwaway leaf) and
  `nix build .#homeConfigurations.scaffold-hm` both succeed.
- `nix flake check` passes in core and the throwaway leaf.

---

## Milestone 2 — Feature set (development tooling)

Goal: the shared development-tooling modules that all machines reuse.

- [ ] Editors:
      - `features/editors/emacs.nix` (homeManager) — package + init via `services.emacs` / doom config
        source strategy (decide in open questions; consider out-of-store symlink for hot reload).
      - `features/editors/nixvim.nix` (homeManager) — neovim via nixvim.
      - `features/editors/vscode.nix` (homeManager) — VS Code, extensions, settings.
- [ ] Dev tools (`features/dev/`): `gh.nix`, `ssh.nix` (read `mine.user.email` for signing/config),
      `direnv.nix`, `toolchains.nix` (node/python/rust/linters/formatters/language servers), `docker.nix`
      (system-level, nixos+darwin guarded).
- [ ] Shell (`features/shell.nix`): zsh/fish choice, starship prompt, completions.
- [ ] Profiles (`modules/profiles/`): `shell`, `dev`, `editors` aggregates composed from the above.
- [ ] Platform guards: any feature that differs between Linux and macOS uses `lib.mkIf` on the platform
      or is split into separate per-platform modules.

**Acceptance criteria**

- Every feature is a single file that contributes to the right module classes.
- A host profile `editors + dev + shell` builds for NixOS, darwin, and standalone HM with the same code.
- No personal or work-specific values in any feature.

---

## Milestone 3 — Personal repo, secrets, deployment

Goal: personal fleet fully working end-to-end with agenix-rekey and deploy-rs.

- [ ] `personal/features/`: tailscale fleet module (enabled via `mine.network.tailscale.enable`), VPN,
      hostname/network policy for the personal network, backup/media services as needed.
- [ ] Personal hosts: `aurora` (desktop), `lapis` (laptop), `hylas` (server, `server` profile + disko),
      `onyx` (Mac, `mkDarwinHost`).
- [ ] `personal/secrets/`: `secrets.nix` (rekey options + secret declarations), `identities/`
      (YubiKey `.pub`), `rekeyed/` (committed), encrypted `.age` files; generators for server secrets
      (WireGuard keys, service passwords, htpasswd).
- [ ] Wire `core.modules/agenix.nix` to read master identities and per-host `hostPubkey` from the leaf,
      and to attach agenix-rekey module to every host.
- [ ] `personal/deploy.nix` via `core.lib.mkDeploy`: nodes for desktop, laptop, servers, Mac; checks
      wired into `nix flake check`.
- [ ] `justfile`: `switch <host>`, `update` (`nix flake update core`), `rekey`, `deploy <node>`,
      `edit-secret <name>`.
- [ ] Document server bootstrap (nixos-anywhere + disko) in the leaf README.

**Acceptance criteria**

- `just deploy hylas` deploys the server from a fresh state using dummy-pubkey bootstrap then real
  host key rekeying.
- Secrets decrypt at activation into `/run/agenix`; services read from those paths.
- `nix flake check` passes in `personal` without a YubiKey plugged in (rekeyed outputs are committed).

---

## Milestone 4 — nix-darwin host

Goal: the Mac host fully working, exercising the darwin side of the framework.

- [ ] Complete `lib/mkDarwinHost.nix`: wire `nix-darwin` `darwinSystem`, home-manager-as-darwin-module,
      core darwin base, `mine.*` options module.
- [ ] `core/modules/darwin/`: homebrew (nix-homebrew), aerospace, macOS system defaults.
- [ ] `personal/hosts/onyx/`: identity + darwin-specific config.
- [ ] Platform-guard audit: ensure darwin-only features (`darwin.*`) and linux-only features
      (`nixos.*`) never cross-contaminate.

**Acceptance criteria**

- `darwin-rebuild switch --flake .#onyx` (or deploy-rs) works on the Mac.
- A core feature like `git` or `emacs` behaves identically on the Mac and on NixOS.

---

## Milestone 5 — Work repo, isolation, nixos-wsl

Goal: work laptop builds from core alone; today HM-only, migrates to nixos-wsl.

- [ ] `work/features/`: work-specific programs, policies, and VPN.
- [ ] `work/hosts/work-laptop/`: identity (work email/name/signing key), `home.nix` (HM-only profile
      via `mkHomeConfig`).
- [ ] `work/secrets/`: work-only agenix-rekey store.
- [ ] `work/deploy.nix` + `justfile`.
- [ ] Isolation audit: confirm work's inputs are only core; run `rg`/`nix eval` checks that no personal
      values or personal secrets paths are referenced.
- [ ] nixos-wsl migration: add `nixos-wsl.nixosModules.wsl` to the work host's `extraModules`;
      switch the work host builder from `mkHomeConfig` to `mkNixosHost` with the wsl module; keep the
      HM-only profile available while transitioning.

**Acceptance criteria**

- `nix build` of the work host succeeds using only `work` + `core` inputs.
- The work laptop's git identity is the work identity; the same core git module is used.
- No `personal` flake reference anywhere in `work`.
- Work host builds as both HM-only and nixos-wsl (module toggled).

---

## Milestone 6 — Hardening, CI, polish

Goal: maintainability and confidence.

- [ ] nixfmt-rfc-style + statix + deadnix configured and passing in all three repos.
- [ ] CI (GitHub Actions or equivalent) per repo: `nix flake check`; core checkable without secrets;
      leaves build committed `rekeyed/` outputs.
- [ ] Optional stub-input pattern in core so any public CI doesn't require private inputs.
- [ ] Optional namaka snapshot tests in core for representative modules.
- [ ] Document `--override-input core path:../core` dev loop in each leaf README.

---

## Verification commands

```bash
# core
cd core && nix flake check && nix flake show

# leaf (personal / work) — after M1
cd personal && nix flake check
nix build .#nixosConfigurations.<host>
nix build .#homeConfigurations.<user>
nix run nixpkgs#nixos-rebuild -- build --flake .#<host>

# secrets (M3+)
cd personal && agenix edit <name> && agenix rekey --flake . && just deploy <node>

# dev loop against a local core checkout
nixos-rebuild switch --flake .#<host> --override-input core path:../core
```

---

## Open questions / follow-ups

- [ ] **Editors**: which editor(s) and how heavy — full nixvim vs. thin wrappers; emacs variant and
      whether the emacs config is itself a separate repo/dir (out-of-store symlink for hot reload).
- [ ] **Core visibility**: keep `core` private, or public/forkable? (It is designed to be forkable.)
- [ ] **Master identity per leaf**: same YubiKey for personal and work secret stores, or separate
      master identities.
- [ ] **nixpkgs channel**: `nixos-unstable` now; consider matching HM/nixos release branches per
      platform later (AD-10, M4).
- [ ] **disko layout**: server partitioning/impermanence specifics.
- [ ] **Deployment of HM-only work laptop**: confirm SSH reachability / `home-manager switch` locally
      inside WSL before deploy-rs.
