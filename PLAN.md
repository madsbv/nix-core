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

---

# Migration: existing `madsbv/nix` → three-repo architecture

**Source:** `github.com/madsbv/nix`, branch `refactor/home-manager-modules` (the current `/etc/nixos/nix`
checkout). Mid-refactor: all five host configurations evaluate, but `nix flake check` fails. The modules
themselves are largely sound; the pain is the wiring between them (`local.*` options, `flake-root` /
`specialArgs` plumbing, preset indirection). This migration therefore **replaces the wiring wholesale**
and ports modules into the new architecture **one module / conceptual feature at a time**, verifying each
in the new wiring before moving on. Stabilizing the old repo is explicitly **not** a goal.

> **Implementation workflow**: the default migration unit is one module or conceptual feature per
> checklist item, but this is not a 1:1 mapping. When porting, you may refactor module internals, split
> or collect old components, or fold helpers into new features if it streamlines things — surface any
> such opportunity to the operator for feedback before implementing it.

## Architecture amendment — nix-darwin (supersedes the darwin items in Milestones 1 and 4)

- **Core keeps a small nix-darwin builder**, `lib/mkDarwinHost.nix`, parallel to `lib/mkNixosHost.nix`.
  It wires the parts of the core featureset shared between NixOS and nix-darwin — the `mine.*` options
  module, agenix, and the core HM features (git, shell, dev, editors, terminal, ssh) — into a
  `darwinSystem`. Core pins `nix-darwin` (AD-6). **No darwin-specific system modules live in core.**
- **All darwin-specific config is personal**: homebrew/nix-homebrew, dock, autorestic, the
  yabai/skhd/sketchybar/karabiner window-management stack, and macOS system defaults. `mbv-mba`
  composes `core.lib.mkDarwinHost` + personal darwin features.

## Decisions recorded (confirmed with the operator)

- **Hostnames stay `mbv-*`** — no rename to aurora/lapis/hylas/onyx. Preserves host keys, `rekeyed/`
  paths, deploy-rs config, tailnet identity, DNS.
- **No dedicated laptop** — current fleet is desktop + 3 servers + Mac; `lapis` is reserved for a future
  machine, and `features/laptop.nix` is ported but only enabled then.
- **Work repo is green-field** — nothing migrates into `work` except shared `core` features; the
  migration scaffolds `work/` anyway.
- **Color-scheme goes to core** — base16 wiring + the `molokai` scheme are generic theming.
- **`keys/builder_ed25519` stays tracked** — it is the macOS linux-builder VM key, not security-sensitive.

## Source inventory (abbreviated)

- **Hosts (5 active)**: `mbv-workstation` (desktop, awesomewm/gaming/steam), `mbv-desktop` (media server
  + CUDA + cinnamon), `mbv-xps13` (home-assistant laptop-server), `hp-90` (slow laptop-server),
  `mbv-mba` (nix-darwin). `ephemeral` (nixos-generators installer) is commented out of `flake.nix`.
- **Module sets**: `systemModules` (builder, common, keys, register-flake, shell, update-diff, users,
  yubikey-agenix-rekey), `nixosModules` (common, home-assistant, laptop, media-server, protonvpn, restic,
  server-laptop, tailscale, users, wifi, yubikey, `detect-hostname-change.nix`), `darwinModules`
  (autorestic, dock), `homeManagerModules` (awesomewm, dev/×13 toolchains, dropbox, emacs, email, git,
  librewolf, neovim, ssh, terminal, user-profile, zathura).
- **Presets**: system/common(+packages/desktop/home-manager/yubikey-agenix-rekey), nixos/common(+awesomewm/
  desktop/efi/server/tracing), darwin/common, home-manager/client(+common/common-packages/nixos),
  secrets/email.
- **Secrets**: agenix-rekey layout — `secrets/{other,restic,ssh,tailscale,protonvpn,generated,
  rekeyed/<host>}/`, `pubkeys/{ssh,yubikey}/`, `keys/`.
- **Other**: `overlays/` (8), `config/` dotfiles, `policy.hujson` + `.github/workflows/tailscale.yml`,
  `golden_test/`, devShell, `justfile`.

## Target mapping

| Source | Target | Notes |
| --- | --- | --- |
| `/etc/nixos/nix` (madsbv/nix) | `personal` | Continues existing git history. |
| — (new) | `core` | Fresh repo, clean history (forkable/public). |
| — (new) | `work` | Fresh repo; only input is `core`. |
| systemModules/common, users, keys, builder, update-diff, register-flake, yubikey-agenix-rekey | core `modules/system/*`, `modules/agenix.nix` | Parameterized: nodes, host keys, identities, master identities come from the leaf via options. |
| nixosModules/common, users, tailscale, yubikey, laptop, detect-hostname-change | core `modules/nixos/base.nix`, `features/tailscale.nix`, `features/laptop.nix` | Personal secret paths (restic/wifi) stripped. `mine.network.tailscale.enable` drives tailscale. |
| homeManagerModules dev/×13, git, ssh, terminal, neovim, emacs, user-profile | core `features/dev/*`, `features/dev/git.nix`, `features/dev/ssh.nix`, `features/shell.nix`, `features/editors/*` | Identity switches from `local.userProfile` to `mine.user.*`. |
| presets system/common(+packages/home-manager), nixos/common, nixos/efi, nixos/tracing, home-manager/common | core profiles + base composites | `nixos/desktop` split: generic (pipewire/lightdm/portal/fonts) → core `desktop` profile; app-specific → personal. |
| overlays/, color-scheme (molokai + base16), nox, devShell; `lib/mkDarwinHost` + minimal darwin wiring; inputs fenix/base16/hosts/direnv-instant/impermanence/disko/deploy-rs/agenix-rekey/nix-auth/nix-darwin | core `overlays/`, `pkgs/`, devShell, `lib/mkDarwinHost.nix`, `flake.nix` | Color scheme per decision; input ownership follows the modules. |
| config/zsh-plugins/p10k-config, config/kitty | core (shell + terminal features) | Relative self-references replace `flake-root`. |
| hosts/×, presets/secrets/email, secrets/, pubkeys/, keys/, policy.hujson, .github/workflows/tailscale.yml, golden_test/ | personal | Hosts keep names. |
| nixosModules home-assistant, media-server, protonvpn, restic, wifi | personal features | Machine/network-specific. |
| **darwinModules dock, autorestic**; `darwin/common` preset; `hosts/mbv-mba/nix-darwin/*`; inputs nix-homebrew + homebrew taps | **personal** (`features/darwin/*`: homebrew, dock, autorestic, window-mgmt) | Per architecture amendment; darwin *builder* stays in core. |
| homeManagerModules awesomewm, dropbox, email, librewolf, zathura; config/{awesome,yabai,skhd,sketchybar,karabiner,svim} | personal features | |
| — (new) | `work/hosts/work-laptop/` + work secrets | HM-only via `mkHomeConfig`; nixos-wsl later. |

## Migration milestones

### M1 — Core framework: replace the wiring (delivers Milestones 0–1)

- [ ] Scaffold `core/` (fresh git history): flake-parts + import-tree auto-loader; `modules/flake-module.nix`.
- [ ] `modules/options.nix` — declare `mine.*` (hostName, user.{username,fullName,email},
      location.{timezone,latitude,longitude}, network.tailscale.enable), ported from `systemModules/common`
      + `homeManagerModules/user-profile`.
- [ ] `modules/agenix.nix` — rekey mechanism from `systemModules/yubikey-agenix-rekey`; options
      `masterIdentities` / `hostPubkey` / `localStorageDir` / `generatedSecretsDir` supplied by the leaf.
- [ ] `modules/system/*` — keys, builder, users framework (rewritten around `mine.user.*` + per-host user
      list; provides home-manager wiring + agenix id-key provisioning), update-diff, register-flake,
      detect-hostname-change.
- [ ] `modules/nixos/base.nix` — from `nixosModules/common`: networking/firewall/nameservers, systemd
      tweaks, openssh, zfs, impermanence base, autoUpgrade (flake URL from leaf), programs, sudo, user
      defaults. Personal secret paths (restic/wifi) stripped.
- [ ] Base composites + builders: `modules/base.nix` (nixos.base + homeManager.base),
      `lib/mkNixosHost.nix`, `lib/mkDarwinHost.nix` (small, shared wiring), `lib/mkHomeConfig.nix`,
      `lib/mkDeploy.nix`.
- [ ] Color-scheme (base16 + `molokai`), overlays, `pkgs` (nox et al.), core devShell, and the core-owned
      flake inputs (fenix, base16, hosts, direnv-instant, impermanence, disko, deploy-rs, agenix-rekey,
      nix-auth, nix-darwin).
- [ ] Proof modules: port `shell` (from `systemModules/shell`) and `git` / `ssh` (from
      `homeManagerModules/{git,ssh}`, reading `mine.user.*`); verify a scratch NixOS host and a standalone
      `mkHomeConfig` both evaluate.

**Acceptance criteria**

- `nix flake check` green in core; scratch host + standalone HM build from core only.
- No darwin-specific system modules in core (builder + shared HM features only).

### M2 — Core-bound modules, one per checklist item

Each item ports one module/feature → one core file, adapting `local.*` → `mine.*`, `flake-root` →
relative refs, `specialArgs` → options. Verified (scratch host + standalone HM + `nix flake check`)
before the next item.

- [ ] `features/dev` toolchains, one per item: fortran, git (lfs), github, go, java, javascript, lua,
      nix, python, R, rust, shell (dev), tools → `features/dev/<name>.nix`.
- [ ] `features/editors/neovim.nix` (from `homeManagerModules/neovim`).
- [ ] `features/editors/emacs.nix` (from `homeManagerModules/emacs`).
- [ ] `features/terminal.nix` (from `homeManagerModules/terminal` + `config/kitty`).
- [ ] `features/tailscale.nix` (from `nixosModules/tailscale`; driven by `mine.network.tailscale.enable`;
      authkey from leaf).
- [ ] `features/yubikey.nix` (from `nixosModules/yubikey`).
- [ ] `features/laptop.nix` (from `nixosModules/laptop`; reserved for a future laptop).
- [ ] Core profiles: `modules/profiles/{base,shell,dev,editors}` aggregates.

**Acceptance criteria**

- Every core feature builds in a scratch NixOS host + standalone HM; `nix flake check` green.
- No personal values or secrets anywhere in core.

### M3 — Personal-bound modules, one per checklist item + host bring-up

- [ ] Scaffold `personal/`: continue `madsbv/nix` history; flake inputs = `core` + `nix-homebrew` +
      homebrew taps; `secrets/` layout (secrets.nix, committed `rekeyed/`, `generated/`), `pubkeys/`,
      `keys/`; wire leaf values into `core.modules/agenix.nix`.
- [ ] `features/desktop` (from `presets/nixos/desktop` generic remainder, `presets/nixos/awesomewm`,
      `homeManagerModules/awesomewm`, `config/awesome`).
- [ ] `features/email` (from `homeManagerModules/email` + `presets/secrets/email`).
- [ ] `features/librewolf`, `features/zathura`, `features/dropbox`.
- [ ] `features/restic` (from `nixosModules/restic`).
- [ ] `features/wifi` (from `nixosModules/wifi` + nmconnection secrets).
- [ ] `features/protonvpn` (from `nixosModules/protonvpn`).
- [ ] `features/media-server` (from `nixosModules/media-server/{jellyfin,transmission,ripping}`).
- [ ] `features/home-assistant` (from `nixosModules/home-assistant` + appdaemon apps).
- [ ] Darwin (personal features on top of `core.lib.mkDarwinHost`): `features/darwin/homebrew`
      (nix-homebrew + casks), `features/darwin/dock` (from `darwinModules/dock`),
      `features/darwin/autorestic` (from `darwinModules/autorestic`), `features/darwin/window-mgmt`
      (yabai/skhd/sketchybar/karabiner from `mbv-mba/nix-darwin` + `config/`), macOS system defaults.
- [ ] Bring up hosts in order as their module set lands (hardware-configuration, disko, configuration,
      per-host identity, deploy node): `mbv-workstation` → `mbv-desktop` → `mbv-xps13` → `hp-90` →
      `mbv-mba` (last).
- [ ] Wire deployment: `personal/deploy.nix` via `mkDeploy` (all 5 nodes), `justfile` (`switch`, `update`,
      `rekey`, `deploy`, `edit-secret`, `nixos-anywhere`/`disko-install`), `policy.hujson` + Tailscale
      ACL workflow, golden-test tooling.

**Acceptance criteria**

- All five hosts build from `personal` + `core`; deploy-rs works; secrets decrypt at activation.
- `darwin-rebuild switch --flake .#mbv-mba` / deploy-rs works on the Mac.

### M4 — Work repo scaffold (delivers Milestone 5)

- [ ] Create `work/` (fresh; only input `core`), `work/hosts/work-laptop/` identity + `home.nix` via
      `mkHomeConfig`, work-only agenix store + committed `rekeyed/`, `deploy.nix` + `justfile`.
- [ ] Isolation audit: input graph is exactly `{core, nixpkgs→core}`; `mine.network.tailscale.enable`
      false; `rg` / `nix eval` show no personal references.
- [ ] Reserve nixos-wsl migration (module toggle, later).

**Acceptance criteria**

- `nix build .#homeConfigurations.<user>` succeeds from `work` + `core` only.

### M5 — Hardening, CI, cleanup (delivers Milestone 6)

- [ ] nixfmt-rfc-style + statix + deadnix in all three repos; CI (`nix flake check`) per repo; document
      `--override-input core path:../core`.
- [ ] Final sweep: per-host `autoUpgrade.flake` → leaf repo, drop dead code (`ephemeral` host, broken
      `presets/nixos/server`), reconcile README/PLAN text with the darwin amendment, optionally update the
      machine inventory (no laptop).

**Acceptance criteria**

- All three repos `nix flake check` green; a fresh-clone build of `personal` and `work` succeeds.

## Migration notes

- **Why one module at a time**: the old repo's modules are mostly sound; its problem is the
  `local.*` / `flake-root` / `specialArgs` / preset wiring. Porting one module per item, each verified in
  the new wiring, isolates legacy-wiring breakage to a single well-scoped change.
- **Input ownership follows modules**: core pins nixpkgs, home-manager, nix-darwin, deploy-rs, agenix,
  agenix-rekey, nix-auth, disko, impermanence, base16, fenix, hosts, direnv-instant (and nox). Personal
  pins nix-homebrew + homebrew taps. Work pins nixos-wsl (later). This is an amendment to AD-6.
- **`keys/builder_ed25519`** stays tracked (macOS linux-builder VM key; not security-sensitive).
- **`ephemeral`** stays out of active config; its installer/ISO role can be rebuilt later on top of core.
