# Implementation Plan

Detailed, milestone-based plan for building the three-repo fleet described in [README.md](./README.md).
Status legend: `[ ]` todo · `[~]` in progress · `[x]` done.

---

## Milestone 0 — Bootstrap scaffolding

> Status: **done** — commits `105277d`, `58b64fb`; verified via `nix flake show` / `nix flake check`.

Goal: three valid, evaluable flakes in sibling directories with the right input topology, proving that
a leaf can consume `core` as an input.

- [x] `core/flake.nix` declares all inputs (nixpkgs, flake-parts, home-manager, nix-darwin,
      agenix-rekey, nixos-wsl, deploy-rs, agenix, treefmt-nix), each following core's nixpkgs where
      applicable.
- [x] `core/flake.lock` is generated (`nix flake lock`) so all inputs are pinned.
- [x] `personal/flake.nix` and `work/flake.nix` declare only `core` (+ `nixpkgs.follows = "core/nixpkgs"`).
- [x] Each directory is a git repo with a `.gitignore` (`/result`, `.direnv/`).
- [x] `nix flake check` passes in `core`; `nix flake metadata` works in `personal` and `work`.

**Acceptance criteria**

- `nix flake show` in `core` shows a valid (if empty) flake.
- `nix flake metadata` in `personal`/`work` resolves `core` and shows `nixpkgs` following `core/nixpkgs`.

---

## Milestone 1 — Core module framework

> Status: **done** — framework scaffolded and green in core (`ca41927` → `2f9d11b`); throwaway
> `personal` and `work` leaves both build and pass `nix flake check`. See
> [Implementation log](#implementation-log).

Goal: the flake-parts + dendritic skeleton with identity options and auto-loading, plus a throwaway
leaf proving cross-repo consumption.

- [x] Add `import-tree`-style auto-loader (`lib/load.nix`; files under `modules/` become flake-parts
      modules; files starting with `_` are treated as helpers and skipped).
- [x] Declare the `mine.*` option namespace in `modules/options.nix` (no defaults):
      `mine.hostName`, `mine.user.{username,fullName,email}`, `mine.location.{timezone,latitude,longitude}`,
      `mine.network.tailscale.enable`, plus `mine.agenix.{enable,masterIdentities,hostPubkey,
      localStorageDir,generatedSecretsDir}`.
- [x] Add `modules/base.nix` composing `nixos.base` / `darwin.base` / `homeManager.base` (initial
      contents: imports of the options module + agenix wiring + minimal per-class base).
- [x] Add representative feature modules to prove the pattern:
      - `features/dev/git.nix` (homeManager; reads `config.mine.user.*`)
      - `features/dev/ssh.nix` (homeManager; minimal stub — email-driven signing/config is M2)
      - `features/shell.nix` (homeManager; zsh + starship + fzf/zoxide/eza/bat)
- [x] Implement `lib/mkNixosHost.nix` (wires options + agenix + home-manager-as-module with
      `useGlobalPkgs`/`useUserPackages`, accepts `hostname`, `profiles`, `modules`, `identity`).
- [x] Implement `lib/mkHomeConfig.nix` (standalone Home Manager; same HM modules + options module, wired
      through the base profile's `homeManager.base` composite instead of `home-manager.sharedModules` — see
      log entry `032e6cc`).
- [x] Implement `lib/mkDarwinHost.nix` (shared NixOS/darwin wiring; full darwin-specific contents in M4).
- [x] Create a throwaway `personal` host (`hosts/scaffold-test/`) that sets `mine.*`, imports core
      profiles, and builds via `mkNixosHost`; plus a throwaway standalone HM config built via
      `mkHomeConfig`. Verify both build. Same for `work` (HM-only, `homeConfigurations.work`).
- [x] Add `lib/mkDeploy.nix` scaffolding (`deploy` + `deployChecks`); leaf wiring lands with the leaf.

**Acceptance criteria**

- A single core feature file produces a Home Manager module usable in both a NixOS-integrated HM and a
  standalone `homeConfigurations` build, reading the same `mine.*` values.
- `nix build .#nixosConfigurations.scaffold-test.config.system.build.toplevel` (in `personal`) and
  `nix build .#homeConfigurations.scaffold-hm.activationPackage` (in `personal` and `work`) succeed.
  Note: the short forms `nix build .#nixosConfigurations.<host>` / `.#homeConfigurations.<user>` fail on
  this nix/nixpkgs pairing ("`type` is not a string but a set") — see implementation log.
- `nix flake check` passes in core and both throwaway leaves.

---

## Implementation log

Running record of what was built and the decisions discovered while doing it. Newest entries on top.

### M3/M4 completion + darwin bring-up (2026-08-09)

Finished the remaining M3 items and brought the darwin host to evaluable state.

- **Update-diff activation hook**: `mine.system.updateDiff.text` was composed but never wired into
  activation. Added `system.activationScripts.preActivation` to `modules/system/update-diff.nix`,
  matching the srvos pattern. Works on both NixOS and nix-darwin.

- **Homebrew audit and wiring**: core `modules/darwin/homebrew.nix` now declares `masApps` option
  (wired to `homebrew.masApps`), sets sensible defaults (`caskArgs.no_quarantine`, `onActivation`
  with `cleanup = "uninstall"` and `upgrade = true`, `enableZshIntegration`, `mutableTaps = false`),
  and provides default standard tap inputs (homebrew-core, cask, bundle, services — added to core's
  `flake.nix`). Leaf taps (felixkratz, pirj, apple) are added in `personal/flake.nix` and wired
  through `mine.darwin.brew.taps` via an inline module in `mbv-mba/default.nix`. Personal
  `features/darwin/homebrew.nix` now uses `mine.darwin.brew.{brews,casks,masApps}` instead of
  raw `homebrew.*`, eliminating option conflicts with core's wiring.

- **`mkDarwinHost` platform fixes**: the NixOS `users.nix` module used `extraGroups`, `isSystemUser`,
  `isNormalUser`, `group`, `openssh.authorizedKeys.keys` — none of which exist on nix-darwin. Split
  into `users.nix` (NixOS) and `users-darwin.nix` (darwin, with auto-assigned UIDs from 501, `home`,
  `description`, `knownUsers`). Removed NixOS-only modules from `darwin.base` imports (`builder.nix`,
  `keys.nix`, `detect-hostname-change.nix`). Removed `system.stateVersion` from `mkDarwinHost`
  (nix-darwin requires an integer, not a NixOS-style string). Added `system.primaryUser` for
  nix-darwin's new user migration.

- **Tailscale fleet module**: extended core `modules/features/tailscale.nix` with fleet options:
  `hostname`, `tags`, `advertiseRoutes`, `advertiseExitNode`. Same options for both NixOS and
  darwin modules, using `extraUpFlags` to pass them through.

- **Personal `mbv-mba` identity**: removed `TODO@example.com`, cleaned up commented-out tap config.
  Homebrew tap inputs (`felixkratz-formulae`, `pirj-noclamshell`, `homebrew-apple`) added to
  `personal/flake.nix` and wired in `mbv-mba/default.nix`.

- **Server secrets generators**: the autorestic generator is already ported. No other generators
  existed in the old repo. The pattern is documented in `autorestic.nix` for future use.

- **Agenix rekeyed dirs**: `rekeyed/mbv-mba/` now exists. The `agenix generate` step ran
  successfully (creating the directory structure), but `agenix rekey` requires the YubiKey to
  produce the actual rekeyed files. The rest of the fleet was already rekeyed in the prior batch.
  `mbv-desktop` doesn't declare any age secrets and doesn't need a rekeyed directory.

- **Build verification**: `nix flake check` passes in all three repos. The darwin host
  (`mbv-mba`) evaluates to a `darwinSystem` derivation — the eval passes through all module
  checks and only fails at the agenix rekeyed-secrets step (which requires a YubiKey). All
  NixOS hosts + standalone HM configs build successfully.

### Builder auto-discovery, identity mirror, and feature profiles

Adopted three improvements from the parallel implementation review:

- **Builders are now auto-discovered flake-parts modules.** Every `.nix` file under `lib/` (except
  `load.nix`) is curried over core's pinned `{ inputs, lib }` and imported as a flake-parts module that
  self-registers on `config.flake.lib`. The framework no longer instantiates builders explicitly in
  `flake-module.nix` — add a new builder file and it's picked up automatically. This also fixes the
  `mkDeploy` leaf API: `mkDeploy` returns a flake-parts module fragment `{ flake.deploy = nodes;
  perSystem = fn; }` that writes the deploy output and per-system deploy-rs checks directly; the leaf
  spreads it into its module body with `let deploy = config.flake.lib.mkDeploy {...}; in { inherit
  (deploy) perSystem; flake.deploy = deploy.flake.deploy; }`.

- **Identity mirror auto-derived from the option surface.** `modules/_hm-mirror.nix` replaces the
  previous `{ inherit (config) mine; }` wholesale copy in `modules/system/users.nix` and
  `lib/mkDarwinHost.nix`. It walks the HM evaluation's `options.mine` and prunes the system-side
  `mine` values to only those the HM eval actually declares. System-only `mine.*` options can now be
  declared in system modules without breaking HM evals. The prune function handles individual options,
  plain option groups (recursed), and submodule options (treated as leaves — `_type == "option"` guard
  prevents descending into option-definition attrsets like `config`/`readOnly`/`default`).

- **Feature profiles as class-keyed aggregates.** `modules/profiles/shell.nix` and
  `modules/profiles/dev.nix` join the existing `base.nix` profile. Each is a class-keyed `{ nixos;
  homeManager; darwin; }` module list. Leaves compose via profile names instead of manually listing
  individual feature modules — e.g. `profiles = [ config.flake.profiles.base config.flake.profiles.dev
  ]` replaces `homeManager = [ git.nix ssh.nix ... ]`. The pattern scales cleanly as more feature
  modules land.

- **Core's pinned inputs re-exported.** `config.flake.inputs` now exposes core's pinned flake inputs,
  letting leaves reference transitive inputs (e.g. `config.flake.inputs.disko.nixosModules.disko`)
  without declaring them as their own flake inputs.

### Review follow-ups — `srvos.*` → `mine.*`, centralized `stateVersion`, darwin deferral, `mkDeploy` API

Review-driven cleanup after the M1 migration:

- **`srvos.*` namespace removed.** The leaf-facing options for update-diff, register-flake, and
  detect-hostname-change were declared in their own system modules under a `srvos.*` namespace, split off
  from the `mine.*` convention (AD-4). They are now `mine.system.updateDiff.{enable,command,text}`,
  `mine.system.registerFlake.{flake,registerSelf}`, and `mine.system.detectHostnameChange.enable`, with
  declarations centralized in `modules/options.nix` — required anyway because the generic `mine` mirror
  into Home Manager evals carries every `mine.*` option. The system modules now only wire behavior.
  srvos remains the attribution source in the file headers.
- **`stateVersion` centralized.** `mine.system.stateVersion` (null default, leaf overrides per host) and
  a derived read-only `mine.system.stateVersionFinal` (core default `"25.05"` when unset) replace the
  hard-coded `"25.05"` that lived in `mkNixosHost`→`users.nix`, `mkHomeConfig`, and `mkDarwinHost`.
  NixOS base (`system.stateVersion`), the integrated HM wiring (`home.stateVersion`), standalone HM, and
  the darwin builder all consume `stateVersionFinal` via `lib.mkDefault`, so a leaf can still set
  `system.stateVersion` / `home.stateVersion` directly. **A warning is emitted at build time when a host
  leaves `mine.system.stateVersion` unset** (guarded by `config ? warnings` so it is safe on module
  systems without that option). All three leaf hosts now set it, demonstrating the encouraged pattern.
- **`builder.nix` darwin branch deferred, not removed.** The `pkgs.stdenv.isDarwin` arm is currently
  unreachable because the module is only imported by `nixos.base`. It is documented in the module and
  wired into a darwin base as part of M4 once darwin hosts exist to exercise it (see Open questions).
- **`mkDeploy` leaf API is broken-by-design; fixing it is the next implementation step (M3).** See the
  dedicated section below.
- **Observation: `mine.system.updateDiff.text` is composed but not yet consumed.** The srvos port sets
  the diff script but nothing wires it into activation (the srvos original consumes `text` elsewhere).
  Keeping behavior identical for now; wiring it into activation is a follow-up.

### `mkDeploy` leaf API — resolved

`mkDeploy` is now an auto-discovered flake-parts module. It returns a module fragment
`{ flake.deploy = nodes; perSystem = { system, ... }: { checks = ...; }; }` that writes the deploy
output and per-system deploy-rs checks directly. The leaf spreads it into its module body via a
`let`-binding (not `//` — the `//` operator forces `config` during module-body evaluation, which
recurses in flake-parts):

```nix
let
  deployModule = config.flake.lib.mkDeploy { system = ...; nodes = { <host> = {... }; };
in
{
  flake.nixosConfigurations.<host> = ...;
  inherit (deployModule) perSystem;
  flake.deploy = deployModule.flake.deploy;
}
```

`options.flake.deploy` is now consumed by mkDeploy's fragment and no longer dead surface. The
builders-as-flake-parts-modules approach makes each builder self-registering and auto-discovered;
see the implementation log entry "Builder auto-discovery".

### Migration M1 — system modules, `nixos/base.nix`, color-scheme, multi-user framework

Completed the M1 port: `modules/system/*`, `modules/nixos/base.nix`, and the molokai/base16 color-scheme
now ship in core, and real hosts build from it. `personal` (NixOS `scaffold-test` + HM `scaffold-hm`) and
`work` (HM `work`) both build; `nix flake check` green in all three repos. Leaves were relocked with
`nix flake update core` after each core change.

- **Users framework (Option B)**: `mine.primaryUser` selects the primary user from a full `mine.users`
  attrset; `mine.user` is a derived alias (`mine.users.<primaryUser>`). Per-user submodule: `username`
  (defaults to the attr key), `fullName`, `email`, `isSystemUser`, `uid`, `gid` (darwin-only), `shell`,
  `extraGroups`, `sshAuthorizedKeys`, `initialHashedPassword`, `homeManagerModules`.
- **Robots + multi-user**: `modules/system/users.nix` maps `mine.users` → `users.users` + per-user
  `home-manager.users` + gated per-user agenix id-key secrets (`id.<host>.<user>`). Non-system users get
  `wheel` automatically and each gets its own HM config (separate browser/WM/desktop); system users become
  robot accounts (locked shell, key-only SSH) and each get a matching `users.groups.<name>`.
- **HM per-user wiring**: per-user HM imports include `{ inherit (config) mine; }` (the system-eval
  mirror) + `home.stateVersion` + the user's `homeManagerModules`. `mkNixosHost` no longer uses
  `home-manager.sharedModules` — importing `homeManager.base` both there and via the primary's
  `profilesHm` re-declared the agenix options. Instead the base composite feeds the primary through
  `profilesHm` and is prepended to additional users' modules via the builder's `users` parameter.
- **`modules/nixos/base.nix`** (curried over `inputs`, imports impermanence's nixos module): ported
  `nixosModules/common` — timezone, `system.autoUpgrade` (leaf flake), networking/nameservers/networkd,
  systemd tweaks, i18n, firmware, neovim/git/zsh, openssh, zfs autosnapshot/scrub, `users.mutableUsers =
  false`, sudo `execWheelOnly`. Impermanence is default-on (`/nix/persist`) behind
  `mine.system.persistence.enable`.
- **Color-scheme**: `modules/color-scheme.nix` ports the `molokai` base16 scheme and wires the base16
  nixos/homeManager/darwin modules defaulting to molokai. New core inputs: `base16`
  (`github:SenchoPens/base16.nix`, deliberately no nixpkgs follow — it only needs `fromYaml`),
  `impermanence` (follows nixpkgs).
- **Other system modules**: keys, builder, update-diff, register-flake, detect-hostname-change ported from
  `local.*` / `flake-root` / hardcoded pubkeys to `mine.*`. Their option declarations are centralized in
  `modules/options.nix` (`mine.ssh.knownHosts.*`, `mine.remoteBuilder.*`, `mine.system.persistence`,
  `mine.system.autoUpgrade`). The builder module adds a remote-build `builder` user + `nix.buildMachines`.

Gotchas / decisions:

- **System-only `mine.*` must be declared centrally**: the generic `{ inherit (config) mine; }` mirror
  carries *every* `mine.*` option into HM evals, so any new system option must be declared in
  `modules/options.nix` (shared by `nixos.base` + `homeManager.base`), not in a system module — otherwise
  HM evals fail with "`option … does not exist`".
- **Impermanence bind-mount rewrite breaks `""`**: `users.<name>.directories = [ "" ]` (whole-home)
  throws `cannot create list of size -1` (`parentsOf ""` → `take (-1)`). Whole-home persistence now uses
  root-level `directories` entries with per-user ownership (`user`/`group`/`mode`).
- **NixOS lockout assertion**: `users.mutableUsers = false` requires a wheel user with an SSH key (or
  password) or a root key; leaf identities must supply one. The scaffold uses a placeholder key.
- **`nix fmt` must run in core** (leaf flakes have no formatter); afterwards `git add -A` again and
  `nix flake update core` in the leaves. Formatting failures also block `nix flake check`.
- **Stale leaf locks hide breakage**: `work` initially failed with `undefined variable 'config'` purely
  because its lock pinned a broken intermediate core commit; `nix flake update core` fixed it.

### `68514b9` `c43b606` — agenix refactor, devShell input closure, README/PLAN reconciliation

Review-driven cleanup addressing the five code/plan divergences noted at the end of M1:

- **`modules/agenix.nix` refactored**: the nixos / homeManager / darwin rekey wiring was triplicated; the
  shared config now lives in a single `mkAgenixModule` helper, parameterized by the per-class module
  imports and a `hostKeyIdentityPaths` flag (only NixOS derives `age.identityPaths` from the openssh host
  keys). No behavior change.
- **`modules/devShell.nix` is curried over core's inputs** (`{ inputs }:` applied in `flake.nix` as
  `(import ./modules/devShell.nix { inherit inputs; })`), matching the `agenix.nix` pattern. It previously
  read `inputs` from the flake-parts module arguments, which would resolve to the *leaf's* inputs (no
  deploy-rs / agenix-rekey) if the module were ever consumed downstream.
- **Docs reconciled with the code** (the five divergence points from review):
  - README: machine inventory updated to the real `mbv-*` naming (no planned laptop; `lapis` reserved);
    the core layout no longer claims a `darwin/` directory (amendment: darwin-specific config lives in
    personal); the builder/feature examples now show the actual consumption pattern
    (`core.flakeModules.default` + `config.flake.*`); `nixfmt-rfc-style` → `nixfmt`.
  - PLAN: migration-M1 status markers updated (throwaway-leaf verification was already done in `2f9d11b`);
    M1's `ssh.nix` item is explicitly a stub, with email-driven signing/config staying on the M2 checklist;
    M1's `mkHomeConfig` description reflects the base-composite wiring (`032e6cc`) rather than
    `home-manager.sharedModules`.

### `2f9d11b` — Milestone 1 complete (throwaway leaves prove cross-repo consumption)

Core commits in this stretch: `ca2d806` (mirror whole `mine.*` into integrated HM evals), `8934a88`
(devShell uses `nixfmt`, not `nixfmt-rfc-style`), `3fac1c0` (parallel-implementation notes), `eab06ee`
(agenix closure over core's inputs), `dbe2236` (nixfmt on `agenix.nix`), `032e6cc` (builders
single-source wiring via the base profile), `2f9d11b` (git feature uses `programs.git.settings`).

- `personal` and `work` are flake-parts leaves: `outputs = inputs@{ self, core, flake-parts, ... }`,
  `flake-parts.lib.mkFlake { inherit inputs; } { imports = [ core.flakeModules.default ./hosts ... ]; }`.
  Direct inputs are exactly `core`, `nixpkgs → core/nixpkgs`, `flake-parts → core/flake-parts`.
- `personal/hosts/scaffold-test/` via `mkNixosHost` (NixOS toplevel builds; a minimal non-bootable
  module satisfies the fileSystems/bootloader/stateVersion assertions) + `personal/home/scaffold-hm` and
  `work/hosts/work-laptop` via `mkHomeConfig`. All three read the same core git/ssh/shell features;
  `mine.user.email` resolves per-leaf (`scaffold@example.com`, `work@example.com`).
- Acceptance verified: `nix build` of the NixOS toplevel and both HM `activationPackage`s, plus
  `nix flake check` in all three repos.

Decisions / gotchas discovered (fed into README/PLAN text where relevant):

- **Nix 2.34 lock bug**: `outputs = { self, inputs, ... }` (bare `inputs` in the pattern) breaks
  `nix flake lock` with `error: cannot find flake 'flake:inputs' in the flake registries`. Use the
  `inputs@{ ... }` @-pattern instead.
- **flake-parts `mkFlake` takes an attrset module**, not a list: `{ imports = [...]; }`. A list gets
  wrapped by `setDefaultModuleLocation` into nested `imports` → "Module imports can't be nested lists".
- **Path-input lock staleness**: `nix flake lock` adds new inputs but does not re-hash existing path
  inputs; after every core commit, leaves need `nix flake update core` before evaluation picks up changes.
- **`nix build .#nixosConfigurations.<host>` and `.#homeConfigurations.<user>` short forms fail** on this
  nix (2.34) / nixpkgs pairing: nix reads `.type` expecting a string, but `nixosSystem` and
  `homeManagerConfiguration` results carry `_type = "configuration"` and a `type` *set*. Reproduced with
  a plain `nixpkgs.lib.nixosSystem` flake, so it is not a framework bug. Use the explicit targets
  `.config.system.build.toplevel` / `.activationPackage` (what `nixos-rebuild` / HM use anyway).
- **`modules/agenix.nix` is curried over core's inputs** (`{ inputs }: _: { ... }`, applied in
  `flake-module.nix` as `(import ./agenix.nix { inherit inputs; })`): a module's `inputs` argument is the
  *leaf's* inputs when the framework is consumed as a flake module, so `inputs.agenix` from inside a
  module resolved to nothing in leaf evals.
- **Builders single-source wiring**: `mkNixosHost`/`mkDarwinHost`/`mkHomeConfig` default to
  `profiles ? [ baseProfile ]` and no longer wire the options/agenix modules directly — the base
  composite is the only place they're imported. Direct wiring caused duplicate option declarations
  ("`rekey.secrets` is already declared").
- **Integrated HM mirrors the whole `mine` subtree** via `{ inherit (config) mine; }` prepended to the
  user's HM `imports`, so new `mine.*` fields flow into integrated HM evals automatically.
- **home-manager git feature uses `programs.git.settings`** (`user.name`, `user.email`, …); the obsolete
  `userName`/`userEmail`/`extraConfig` aliases carry deprecation traces.
- treefmt gotcha re-confirmed: untracked files fail the sandboxed `nix flake check` until staged; clear
  `~/.cache/treefmt` after formatter config changes.

### `ca41927` — core framework scaffold (Milestone 0 + migration M1 framework part)

Verified with `nix flake show` + `nix flake check` in `core` (x86_64-linux).

- `flake.nix`: inputs include `agenix` and `treefmt-nix` (both follow `nixpkgs`); exports
  `flake.flakeModules.default` = the framework module, closed over core's pinned `inputs`.
- `modules/flake-module.nix`: the self-contained flake-parts module. Imports
  `flake-parts.flakeModules.modules`, `home-manager.flakeModules.default`, `nix-darwin.flakeModules.default`,
  `agenix.nix`, `base.nix`, and auto-loaded `features/` + `profiles/` trees. Declares
  `options.flake.{profiles,lib,deploy,flakeModules}` and instantiates the builders into `config.flake.lib`.
- `lib/load.nix`: curried auto-loader `{ skip ? ... } : { dir } : [ modules... ]`; `_`-prefixed files
  skipped; deterministic sorted traversal.
- `modules/options.nix`: `mine.*` + `mine.agenix.*` as in M1. No defaults; `masterIdentities` gets a
  placeholder default (`[{ identity = "/dev/null"; }]`) so agenix-rekey's unconditional assertion passes
  before the leaf enables agenix.
- `modules/agenix.nix`: per-class modules under `flake.modules.{nixos,homeManager,darwin}.agenix`, each
  importing `inputs.agenix.<class>.age` + `inputs.agenix-rekey.<class>.agenix-rekey`. Runtime wiring is
  gated on `mine.agenix.enable`; `age.rekey.masterIdentities` is always set (`lib.mkDefault`).
- `lib/mkNixosHost.nix`, `lib/mkHomeConfig.nix`, `lib/mkDarwinHost.nix`, `lib/mkDeploy.nix`: builders
  read `config.flake.modules` / `config.flake.profiles` (no hardcoded core paths). `home.stateVersion`
  defaulted `"25.05"`; standalone HM sets `home.username` / `home.homeDirectory` explicitly (no defaults
  for stateVersion ≥ 20.09).
- `modules/treefmt.nix` + `modules/devShell.nix`: treefmt-nix (`nixfmt`, `deadnix`, `statix`; `nixfmt` is
  rfc-style in current nixpkgs) wired into `nix flake check`; devShell with git, just, age,
  age-plugin-yubikey, nixfmt-rfc-style, statix, deadnix, deploy-rs, agenix-rekey.

Gotchas / decisions (feed into README/PLAN text where relevant):

- `lib.mkIf` is **not** allowed directly in a module's `imports` list ("expected a list but found a set").
  Conditional wiring goes inside the module body (`config.age = lib.mkMerge [ ... (lib.mkIf ...) ]`).
- flake-parts already declares `flake.checks` (transposed per-system, `lazyAttrsOf package`); do **not**
  redeclare it. Leaves wire deploy-checks through `perSystem.checks` instead.
- Flake files must be git-tracked before evaluation ("Path … is not tracked by Git").
- treefmt caches (`~/.cache/treefmt`); after changing formatter config, clear the cache or `nix fmt`
  will skip files and disagree with `nix flake check`.

Remaining for Milestone 1:

Done. M1 acceptance met (see log entry `2f9d11b`). `mkDeploy`/`justfile` leaf wiring deferred to M3/M5.

### M3 import-gating conversion (2026-08-09)

Removed every `mine.<feature>.enable` option and `lib.mkIf` wrapper across all core and personal
modules, converting to pure import-gating. Modules now activate unconditionally when imported;
disabling means not importing.

**Core** (`0b7d525`, `dae4246`, `ee9e4c6`):
- Removed 10 enable option declarations from `options.nix`: `tailscale`, `ssh.knownHosts`,
  `remoteBuilder.{enableLocalBuilder,enableRemoteBuilders}`, `prefetch`, `system.persistence`,
  `system.autoUpgrade`, `system.updateDiff`, `system.detectHostnameChange`, `agenix`
- Removed `mkIf` wrappers from all system modules (`keys`, `builder`, `builder-darwin`, `agenix`,
  `users`, `nixos/base` autoUpgrade, `nixos/persistence`, `detect-hostname-change`, `base` nixos)
- Removed enable options and `mkIf`s from feature modules: `tailscale`, `yubikey`, `rust`,
  `docker`, `homebrew`, `linux-builder`
- Rust now uses a NixOS-level overlay (via new `nixos.rust` module in dev profile) for
  `useGlobalPkgs` compatibility

**Personal** (`e45ae93`):
- Removed enable options and `mkIf`s from all 14 personal feature modules
- Added NixOS-level option stubs for `librewolf` (deviceName) and `email` (muAddressArgs,
  pmbridgePasswordFile) so host identities can set these in the system eval for HM mirroring
- Created `features/email/secrets.nix` wiring age.secrets for mbsyncrc, mu-init-addresses,
  pmbridge-password
- Wired email into `personal-desktop` (NixOS + HM) and `personal-darwin` (HM only) profiles
- Fixed pre-existing `restic.nix` operator precedence bug (`args.grace or daysToSecs 10` →
  `args.grace or (daysToSecs 10)`) — previously hidden behind the enable gate
- Fixed pre-existing `home-assistant` appdaemon path (`./appdaemon/apps` → `./appdaemon`)
- Fixed pre-existing `dropbox` path (`~/Dropbox` → `${config.home.homeDirectory}/Dropbox`)
- Added `nixpkgs.config.allowUnfree` for mbv-workstation (needed by dropbox/steam)
- Added `mine.librewolf.deviceName` to mbv-workstation identity
- Added agenix `hostPubkey` to scaffold-test (no longer optional)
- Removed stale `enable = true/false` lines from all 5 host identity files

### M3 review follow-ups (2026-08-09)

Review of the M3 implementation work so far against the plan and the "semantic porting"
directive from [AGENTS.md](./AGENTS.md). Full review report in the working-copy git log.

#### Findings and resolutions

- **AwesomeWM was in core despite PLAN.md saying personal.** Resolved by splitting the
  config: the generic `rc.lua` (layouts, keybindings, signals, wibar, default rules) stays in
  core; application-to-tag rules (Steam→7, Discord→8) are in `personal/features/awesomewm/rules.lua`,
  loaded by core rc.lua via `dofile()`. Core's default `rules.lua` uses `lib.mkDefault` so the
  leaf's version wins by priority. This also establishes the pattern for other config files
  that need per-host customization.
- **Zathura has no `mine.zathura.enable` option.** This is intentional — it follows the
  preferred import-gating pattern (import = enable, don't import = disable). Not a bug.
- **Email age secrets not ported from `presets/secrets/email`.** Intentional — they will be
  defined when hosts are wired up. Noted in Migration notes.
- **WiFi/ProtonVPN age secret paths renamed during porting.** Noted in Migration notes;
  verify old `.age` file paths during host bring-up.
- **rc.lua was a byte-for-byte copy from the old repo.** The "semantic porting" directive
  targets nix architecture and wiring, not application config files with single-purpose
  formats. The rc.lua content itself is fine as-is; the architectural improvement is the
  dofile-based rules extension point.

#### Added to the plan

- **Import-gating decision** recorded under Decisions recorded, with the grandfathered
  enable-gated module list.
- **M3 checklist** updated with granular sub-items for features, secrets, and deploy,
  marking ported modules and profiles as done.

---

## Milestone 2 — Feature set (development tooling)

Goal: the shared development-tooling modules that all machines reuse.

- [x] Editors:
      - `features/editors/emacs.nix` (homeManager) — `services.emacs`; DOOMDIR builder deferred.
      - `features/editors/nixvim.nix` (homeManager) — neovim via nixvim (oxalica overlay pattern).
- [x] Dev tools (`features/dev/`): `gh.nix`, `ssh.nix` (extended with `mine.ssh.signingKey` + full
      client config), `direnv.nix`, per-language toolchains (`python.nix`, `shell.nix`, `go.nix`,
      `rust.nix` via oxalica, `javascript.nix`, `java.nix`, `lua.nix`, `nix.nix`, `fortran.nix`,
      `R.nix`, `tools.nix`), `docker.nix` (nixos+darwin guarded).
- [x] Shell (`features/shell.nix`): zsh + starship + fzf/zoxide/eza/bat.
- [x] Additional features: `features/terminal.nix` (alacritty), `profiles/terminal.nix`.
- [x] Profiles (`modules/profiles/`): `shell`, `dev`, `editors`, `terminal` aggregates.
- [x] Platform guards: docker uses per-class modules (nixos/darwin); homebrew is a darwin core module.
- [x] New core inputs: nixvim, rust-overlay (oxalica), nix-homebrew, direnv-instant.

**Acceptance criteria**

- [x] Every feature is a single file that contributes to the right module classes.
- [x] A host profile `editors + dev + shell` builds for NixOS and standalone HM with the same code.
- [x] No personal or work-specific values in any feature.

---

## Milestone 3 — Personal repo, secrets, deployment

Goal: personal fleet fully working end-to-end with agenix-rekey and deploy-rs.

- [x] **Fix `mkDeploy`'s leaf API** — resolved in `ae8fad6` via builders-as-flake-parts-modules;
      the scaffold already uses the new pattern (see implementation log).
- [x] `personal/features/`: all personal-bound feature modules ported and converted to
      import-gating (see implementation log "M3 import-gating conversion").
  - [x] Personal-bound feature modules ported: librewolf, dropbox, restic, wifi, protonvpn, email,
        zathura, darwin (dock, autorestic, yabai, skhd, sketchybar, karabiner).
  - [x] Personal profiles created: `personal-desktop`, `personal-darwin`.
  - [x] AwesomeWM rules extracted to `personal/features/awesomewm/rules.lua`; core rc.lua loads
        per-host `rules.lua` via `dofile()`, defaulting to core's empty rules.lua via `lib.mkDefault`.
  - [x] All enable-gated modules converted to import-gating.
   - [x] tailscale fleet module (hostname, tags, routes, exit-node options added to core).
- [x] Personal hosts: `mbv-workstation`, `mbv-desktop`, `mbv-xps13`, `hp-90` all build and pass
       `nix flake check` (x86_64-linux). `mbv-mba` (Mac, `mkDarwinHost`) evaluates to
       `darwinSystem` derivation — pending rekey+deploy on aarch64-darwin to fully verify.
- [~] `personal/secrets/`: `secrets.nix` (rekey options + secret declarations), YubiKey `.pub`
      files, `rekeyed/` (committed), encrypted `.age` files; generators for server secrets
      (WireGuard keys, service passwords, htpasswd).
  - [x] `secrets.nix` scaffolded with YubiKey identities.
  - [x] SSH id-key secrets ported for all 5 hosts.
  - [x] Email age secrets wired via `features/email/secrets.nix`.
   - [x] `rekeyed/` populated; remaining encrypted `.age` files ported from old repo.
   - [x] Generators for server secrets (autorestic generator already ported; no other generators in old repo).
- [x] Wire `core.modules/agenix.nix` to read master identities and per-host `hostPubkey` from the leaf,
      and to attach agenix-rekey module to every host. (Already wired — agenix now always active;
      hostPubkey required on all hosts.)
- [x] `personal/deploy.nix` via `core.lib.mkDeploy`: nodes for all 5 personal hosts; checks wired
      into `nix flake check`.
  - [x] Scaffold `scaffold-test` deploy node wired.
  - [x] Real host nodes for all 5 hosts wired.
- [x] `justfile`: `switch <host>`, `update` (`nix flake update core`), `rekey`, `deploy <node>`,
      `edit-secret <name>`.
- [ ] Document server bootstrap (nixos-anywhere + disko) in the leaf README.

**Acceptance criteria**

- `just deploy <server>` deploys a server from a fresh state using dummy-pubkey bootstrap then real
  host key rekeying.
- Secrets decrypt at activation into `/run/agenix`; services read from those paths.
- `nix flake check` passes in `personal` without a YubiKey plugged in (rekeyed outputs are committed).

---

## Milestone 4 — nix-darwin host

Goal: the Mac host fully working, exercising the darwin side of the framework.

- [x] Complete `lib/mkDarwinHost.nix`: wire `nix-darwin` `darwinSystem`, home-manager-as-darwin-module,
       core darwin base, `mine.*` options module. Split `users.nix` → `users-darwin.nix` for
       platform-compatible user management. Set `system.primaryUser`.
- [x] `core/modules/darwin/`: homebrew (nix-homebrew with standard taps as core defaults, `masApps`,
       general brew settings like `caskArgs.no_quarantine`, `onActivation`, `enableZshIntegration`,
       `mutableTaps = false`).
- [x] `personal/hosts/mbv-mba/`: identity + darwin-specific config, homebrew tap inputs (felixkratz,
       pirj, homebrew-apple), personal brew casks/masApps wired through `mine.darwin.brew.*`.
- [x] Platform-guard audit: NixOS-only system modules extracted from `darwin.base` imports; darwin
       gets its own user module and keeps only `builder-darwin.nix`, `register-flake.nix`,
       `update-diff.nix`.
- [x] Darwin eval reaches `darwinSystem` derivation; pending rekey + deploy on aarch64-darwin hardware.

**Acceptance criteria**

- `darwin-rebuild switch --flake .#mbv-mba` (or deploy-rs) works on the Mac.
- A core feature like `git` or `emacs` behaves identically on the Mac and on NixOS.

---

## Milestone 5 — Work repo, isolation, nixos-wsl

Goal: work laptop builds from core alone; today HM-only, migrates to nixos-wsl.

- [ ] `work/features/`: work-specific programs, policies, and VPN.
- [x] `work/hosts/work-laptop/`: throwaway identity + HM-only profile via `mkHomeConfig` (built and green
      in M1); real work email/name/signing key land with `work/features/`.
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
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
nix build .#homeConfigurations.<user>.activationPackage
nix run nixpkgs#nixos-rebuild -- build --flake .#<host>

# secrets (M3+)
cd personal && agenix edit <name> && agenix rekey --flake . && just deploy <node>

# dev loop against a local core checkout
nixos-rebuild switch --flake .#<host> --override-input core path:../core
```

---

## Open questions / follow-ups

- [x] **Editors**: resolved — nixvim + packaged emacs via `services.emacs`; the emacs config is
      nix-managed as a store-built `$DOOMDIR` (Option 3) — see
      "Doomemacs — Option 3: store-built DOOMDIR" under Decisions recorded.
- [ ] **Core visibility**: keep `core` private, or public/forkable? (It is designed to be forkable.)
- [ ] **Master identity per leaf**: same YubiKey for personal and work secret stores, or separate
      master identities.
- [ ] **nixpkgs channel**: `nixos-unstable` now; consider matching HM/nixos release branches per
      platform later (AD-10, M4).
- [ ] **disko layout**: server partitioning/impermanence specifics.
- [ ] **Deployment of HM-only work laptop**: confirm SSH reachability / `home-manager switch` locally
      inside WSL before deploy-rs.
- [ ] **mkDeploy leaf API**: the builder returns `{deploy; checks}`, which a leaf must split across
      `config.flake.deploy` and `perSystem.checks` (call twice / capture); `options.flake.deploy` is
      unused; `deployChecks` transposition can't be written by a plain function. Fix as the first M3
      item, likely via builders-as-flake-parts-modules. See the implementation log section "mkDeploy leaf
      API — known issues and next step".
- [x] **builder.nix on darwin**: resolved — the `isDarwin` branch was split into a separate
      `builder-darwin.nix` module, imported only by `darwin.base`. The common `builder.nix` module is
      imported by both `nixos.base` and `darwin.base`.
- [x] **update-diff activation**: `mine.system.updateDiff.text` is composed but not yet consumed by any
       activation hook (the srvos original wires it elsewhere). Decide whether to wire it or drop it.
       **Resolved**: wired into `system.activationScripts.preActivation` in the update-diff module,
       works on both NixOS and darwin.

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
  `darwinSystem`. Core pins `nix-darwin` (AD-6). **nix-homebrew is a core concern** — the
  `modules/darwin/homebrew.nix` module imports `nix-homebrew.darwinModules.nix-homebrew` and declares
  `mine.darwin.brew.*` options (taps, brews, casks). Leaves supply tap inputs and package lists;
  core handles the wiring.
- **Remaining darwin-specific config is personal**: dock, autorestic, the
  yabai/skhd/sketchybar/karabiner window-management stack, and macOS system defaults. `mbv-mba`
  composes `core.lib.mkDarwinHost` + personal darwin features.

## Decisions recorded (confirmed with the operator)

- **Hostnames stay `mbv-*`** — preserves host keys, `rekeyed/`
  paths, deploy-rs config, tailnet identity, DNS.
- **No dedicated laptop** — current fleet is desktop + 3 servers + Mac; `lapis` is reserved for a future
  machine, and `features/laptop.nix` is ported but only enabled then.
- **Work repo is green-field** — nothing migrates into `work` except shared `core` features; the
  migration scaffolds `work/` anyway.
- **Color-scheme goes to core** — base16 wiring + the `molokai` scheme are generic theming.
- **`keys/builder_ed25519` stays tracked** — it is the macOS linux-builder VM key, not security-sensitive.
- **Doom config is nix-managed as a store-built `$DOOMDIR`** (Option 3) — `nix build
  .#doomdirs.<host>` composes core + the active leaf into a store dir that `~/.config/doom` symlinks
  to; identity is injected from `mine.*` via a generated `identity.el`; personal and work keep
  isolated doom overlays. Full architecture in "Doomemacs — Option 3: store-built DOOMDIR" below. The
  framework stays `git clone doomemacs/core` + `bin/doom install` (module library via the
  `sources/doom+` submodule) so `doom sync` can derive versions.
- **Import-gating is the module pattern.** All modules use pure import-gating: importing a
  module activates it unconditionally; disabling a feature means not importing the module. This
  keeps the import/not-import decision at the flake-parts module level (host config / profile)
  rather than inside the module body. All modules were converted to import-gating in the M3
  refactor (see implementation log).

## Doomemacs — Option 3: store-built DOOMDIR

The doom config is nix-managed end to end. A single derivation composes the whole `$DOOMDIR` from
core's shared doom tree + the active leaf's overlay and materializes it in the store; `~/.config/doom`
is a symlink to the store result. This supersedes the earlier "Doom config stays a live checkout"
decision above. Rapid iteration is preserved two ways: (a) elisp edits are evaluated directly in a
running emacs, and (b) a full reload is `just doomdir` — a ~1–4 s build + relink + `doom sync`, not a
host rebuild.

### Layering (core + leaf composition)

Doom reads exactly one `$DOOMDIR` and has no native layering, so composition happens inside the
derivation:

- **M2 — fragment loading.** Core `config.el`/`packages.el` end with
  `(load! "config-extra" (doom-user-dir))` / `(load! "packages-extra" ...)`; the leaf fragments are
  copied alongside. The `:user` module (depth `(-105 . 105)`, path `doom-user-dir`) loads config last,
  and `package!`/config context is dynamically bound, so leaf fragments override core last.
- **M3 — module union.** `modules/` is the union of core + leaf module dirs; leaf copies overwrite
  core on name collision (Doom's first-match module resolution). Private modules shadow builtins of
  the same name.
- **M4b — manifest concat.** `init.el` = `core/doom/init.el` ++ `leaf/init-extra.el` (two `doom!`
  blocks). Verified safe in doomemacs v3: `doom!` is idempotent per module (`doom-module--put` →
  `puthash` keyed by `(group . name)`, last call wins).
- **M5 — identity.** `identity.el` generated from a minimal `mine.*` evaluation (below).

### Builder: `core/lib/mkDoomdir.nix`

Curried over core's pinned inputs (mkHomeConfig pattern). Signature:
`{ system, hostname, coreDir ? (inputs.self + "/doom"), leafDir, identity ? [ ] }` → derivation.

- `coreDir` defaults to core's own doom tree (`inputs.self/doom`, resolved to the *locked* core input
  inside leaf evals); `leafDir` is the leaf's `self/doom` (always fresh).
- **Identity extraction decouples eval from host builds.** `mine` comes from a standalone
  `lib.evalModules` run importing `modules/options.nix` + the host's `identity.nix` (the same module
  files the host builders use — single source of truth). ~100 ms of eval, NOT the full
  NixOS/home-manager evaluation. Pulling `mine` from `config.flake.nixosConfigurations.<host>` instead
  would force a full host eval (+5–30 s).
- The derivation is pure file ops (`runCommand` + bash): concat init.el, copy config/packages +
  fragments, union modules/, write identity.el. No elisp compilation (elpa/melpa still go through
  `doom sync`). Content-addressed: only changed inputs re-realize.

### Flake surface: `flake.doomdirs.<host>`

- Core declares `options.flake.doomdirs` (`lazyAttrsOf raw`) and adds `flake.lib.mkDoomdir`.
  flake-parts' `flake` option is an open submodule, so `config.flake.doomdirs.<host>` becomes a raw
  top-level output and `nix build .#doomdirs.<host>` resolves it (raw top-level attr paths work — same
  as `.#homeConfigurations.<user>...`). No hostname-based alias; the justfile fills in `<host>`.
- Leaf registers per host (e.g. `hosts/default.nix`):
  `config.flake.doomdirs."<host>" = config.flake.lib.mkDoomdir { system = ...; leafDir = ./doom;
  identity = [ ./<host>/identity.nix ]; }`.

### Leaf + core scaffolding

Each leaf gets a `doom/` overlay: `init-extra.el` (leaf `doom!` additions), `config-extra.el`,
`packages-extra.el`, `modules/`. Core gets `doom/init.el`, `doom/config.el`, `doom/packages.el`,
`doom/modules/`, the M2 trailers, and the read-only redirects.

### Read-only DOOMDIR redirects (core `doom/config.el`)

The store dir is read-only, so core config.el redirects runtime writes:
`custom-file` → `$XDG_STATE_HOME/doom/custom.el`, `custom-theme-directory` → XDG, plus the
transient/history redirects Doom v3 doesn't already send to XDG. `snippets/`/`autoload/` are baked
read-only (config-in-nix). These are the one behavior change vs the live-checkout design and ship once
in core.

### Core justfile helper

```make
leaf := `[[ -d ../personal ]] && echo ../personal || echo ../work`
host := `hostname`

# Rebuild the store DOOMDIR, relink ~/.config/doom, then doom sync.
doomdir:
    set -euo pipefail
    out=$(nix build --print-out-paths "{{leaf}}#doomdirs.{{host}}")
    if [ -e "$HOME/.config/doom" ] && [ ! -L "$HOME/.config/doom" ]; then
        echo "error: $HOME/.config/doom exists and is not a symlink" >&2; exit 1
    fi
    ln -sfn "$out" "$HOME/.config/doom"
    "$HOME/.config/emacs/bin/doom" sync
```

`doom sync` requires the framework git checkout (`~/.config/emacs`, from `doom install`) — matching the
v3 requirement that the emacs dir stay a git checkout for version derivation and the per-profile
generated init.

### Evaluation scope & time

`nix build .#doomdirs.<host>` forces: lock resolution, flake-parts top-level structure, the requested
host's identity mini-eval, a small `pkgs` closure (runCommand/stdenv), and realization. It does NOT
force host configs, HM activation packages, other systems, or the nixpkgs bulk — `flake.doomdirs` is a
lazy attr, so only the selected host is touched. Estimate **~1–4 s total, eval ~1–3 s**.

Workflow caveats: core `doom/` edits require commit + `nix flake update core` in the leaves before a
leaf build sees them (path-input narHash pin — same ordering as every core change); leaf `doom/` edits
surface immediately.

### Acceptance

- `nix build .#doomdirs.<host>` in personal/work produces a store dir with the composed init.el /
  config.el+extra / packages.el+extra / modules union / identity.el.
- `just doomdir` relinks `~/.config/doom` and runs `doom sync`.
- `nix flake check` green in all three repos.

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

> Status: **done** — framework (`ca41927` → `2f9d11b`), `modules/system/*`, `modules/nixos/base.nix`, and
> color-scheme all landed; `personal` (NixOS + HM) and `work` (HM) build and pass `nix flake check`.
> The remaining sub-items (overlays/`pkgs`, fenix/hosts/direnv-instant/disko/nix-auth inputs) are not
> needed for host builds; they stay on the M2/M6 checklists.

- [x] Scaffold `core/` (fresh git history): flake-parts + import-tree auto-loader; `modules/flake-module.nix`.
- [x] `modules/options.nix` — declare `mine.*` (hostName, user.{username,fullName,email},
      location.{timezone,latitude,longitude}, network.tailscale.enable), ported from `systemModules/common`
      + `homeManagerModules/user-profile`. (Plus `mine.agenix.*`.)
- [x] `modules/agenix.nix` — rekey mechanism from `systemModules/yubikey-agenix-rekey`; options
      `masterIdentities` / `hostPubkey` / `localStorageDir` / `generatedSecretsDir` supplied by the leaf.
- [x] `modules/system/*` — keys, builder, users framework (rewritten around Option B: `mine.primaryUser` +
      full `mine.users` attrset, `mine.user` derived; provides per-user home-manager wiring + agenix
      id-key provisioning), update-diff, register-flake, detect-hostname-change.
- [x] `modules/nixos/base.nix` — from `nixosModules/common`: networking/firewall/nameservers, systemd
      tweaks, openssh, zfs, impermanence base, autoUpgrade (flake URL from leaf), programs, sudo, user
      defaults. Personal secret paths (restic/wifi) stripped.
- [x] Base composites + builders: `modules/base.nix` (nixos.base + homeManager.base),
      `lib/mkNixosHost.nix`, `lib/mkDarwinHost.nix` (small, shared wiring), `lib/mkHomeConfig.nix`,
      `lib/mkDeploy.nix`.
- [x] Color-scheme (`modules/color-scheme.nix`: base16 nixos/homeManager/darwin modules defaulting to the
      ported `molokai` scheme) + core inputs `base16` (`github:SenchoPens/base16.nix`, no nixpkgs follow)
      and `impermanence` (follows nixpkgs). Core devShell + treefmt-nix done.
- [ ] Overlays, `pkgs` (nox et al.), and the remaining core-owned inputs (fenix, hosts, direnv-instant,
      disko, nix-auth) — not needed for host builds; deferred.
- [x] Proof modules: `shell`, `git`, and `ssh` feature files, plus a scratch NixOS host and a standalone
      `mkHomeConfig`, verified in both `personal` and `work` (`2f9d11b`). *(Written from scratch rather than
      ported from the old repo; `git` reads `mine.user.*`. `ssh` is a minimal stub here — its email-driven
      signing/config stays on the M2 checklist.)*

**Acceptance criteria**

- `nix flake check` green in core; scratch host + standalone HM build from core only.
- Real hosts build: `.#nixosConfigurations.scaffold-test.config.system.build.toplevel` (personal) plus
  `.#homeConfigurations.{scaffold-hm,work}.activationPackage` (personal, work); robot/service accounts and
  multiple human users with separate HM configs verified via `nix eval`.
- No darwin-specific system modules in core (builder + shared HM features only).

### M2 — Core-bound modules, one per checklist item

> Status: **nearly done** — toolchains, editors, terminal, profiles, tailscale, yubikey all built.
> Only `laptop` feature remains (reserved for future machine).

Each item ports one module/feature → one core file, adapting `local.*` → `mine.*`, `flake-root` →
relative refs, `specialArgs` → options. Verified (scratch host + standalone HM + `nix flake check`)
before the next item.

- [x] `features/dev` toolchains, one per item: fortran, git, gh, go, java, javascript, lua,
      nix, python, R, rust, shell (dev), tools → `features/dev/<name>.nix`. All 13 built fresh;
      adapts `local.*` → `mine.*`.
- [x] `features/editors/neovim.nix` (implemented via nixvim: `neovim.nix` + curried `_nixvim.nix`).
- [x] `features/editors/emacs.nix` (wires `services.emacs`; DOOMDIR builder deferred).
- [x] `features/terminal.nix` (alacritty + JetBrains Mono, written fresh).
- [x] `features/tailscale.nix` (NixOS + darwin `services.tailscale` with `--ssh`; HM packages CLI;
      `mine.network.tailscale.authKeyFile` for pre-shared-key hosts).
- [x] `features/yubikey.nix` (NixOS + darwin `services.yubikey-agent` + CLI tools; HM packages CLI).
      Personal secrets infrastructure created in the leaf (pubkeys, encrypted files, `secrets.nix`).
- [ ] `features/laptop.nix` (from `nixosModules/laptop`; reserved for a future laptop).
- [x] Core profiles: `modules/profiles/{base,system,shell,dev-base,dev,editors,terminal}` aggregates.

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
- [ ] Darwin (personal features on top of `core.lib.mkDarwinHost`): `features/darwin/dock` (from `darwinModules/dock`),
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
  agenix-rekey, treefmt-nix, nix-auth, disko, impermanence, base16, fenix, hosts, direnv-instant (and
  nox). Personal pins nix-homebrew + homebrew taps. Work pins nixos-wsl (later). This is an amendment to
  AD-6.
- **`keys/builder_ed25519`** stays tracked (macOS linux-builder VM key; not security-sensitive).
- **`ephemeral`** stays out of active config; its installer/ISO role can be rebuilt later on top of core.
- **WiFi and ProtonVPN age secret paths were renamed during porting.** When hosts are wired up,
  verify that encrypted `.age` files at these paths exist or rename them accordingly:
  - WiFi: `spiderlan-nm` → `wifi-spiderlan`, `att-nm` → `wifi-att`, `synapse-nm` → `wifi-synapse`,
    `vindbjerggaard` → `wifi-vindbjerggaard`.
  - ProtonVPN: `mbv-desktop-protonvpn` → `protonvpn-wg`.
- **Email age secrets (`mbsyncrc`, `mu-init-addresses`, `pmbridge-password`) are not defined**
  in the ported email module. They were previously in `presets/secrets/email/default.nix`. Define
  them in the host configuration (or a host-level secrets module) when wiring up hosts with email.

## Notes from the parallel implementation

These capture ideas and findings surfaced while reviewing a parallel implementation of the
same architecture. Entries marked **[adopted]** have been implemented.

- **[adopted] Mirror identity values into the Home Manager evaluation.** On NixOS/nix-darwin hosts,
  Home Manager evaluates in its own module system: values set for `mine.*` in the system
  evaluation are not visible to feature modules inside the HM evaluation. The host wiring
  must explicitly re-define the `mine.*` values in the HM evaluation, mirroring the system
  values, for value-driven features (AD-4) to work in integrated mode. The mirrored field list
  is now derived from the declared options via `modules/_hm-mirror.nix` (a prune-based walk of
  `options.mine` in the HM eval), so adding a new `mine.*` subtree flows through automatically.
  Motivation: identity injection only functions in the integrated HM path if this copy exists,
  and a hard-coded copy list drifts silently.
- **[adopted] Builders as flake-parts modules.** The builders are now flake-parts modules
  auto-discovered from `lib/`, each self-registering on `config.flake.lib`. They are curried
  over core's pinned `{ inputs, lib }` (preserving the invariant that core's inputs are used,
  not the leaf's). Dependencies on `config.flake.profiles.*` / `config.flake.modules.*` are
  resolved from the flake-parts module body, which merges all modules before evaluation.
  Motivation: this removes the manual dependency threading in the framework module, keeps
  builders automatically in sync with whatever the framework registers, and fixes `mkDeploy`'s
  leaf API (the builder can now return a module fragment with `flake.deploy` + `perSystem`).
- **Port by semantics, not by wiring.** When porting an old module, judge it on its contents
  and what it configures, not on whether it currently builds or what its preset/wrapper
  plumbing looks like — that wiring is being replaced wholesale. Decide each module's
  destination (core base / core feature / leaf / drop) from its semantics, then port its
  content. Motivation: modules entangled in legacy plumbing are often still sound; dropping
  them because of a broken wrapper loses working functionality.
- **Doomemacs: distinguish the config dir from the framework dir.** `~/.config/doom` is the user's
  config (now a symlink to a store-built DOOMDIR — see "Doomemacs — Option 3: store-built DOOMDIR"
  under Decisions recorded), while `~/.config/emacs` is the framework install — `git clone`
  `doomemacs/core` plus `bin/doom install` (initializes the `sources/doom+` submodule). Do not let a
  leaf symlink a config dir onto `~/.config/emacs`; that would clobber the framework, and `doom sync`
  needs the emacs dir to be a git checkout. Identity is injected from `mine.user.*` + hostname via
  the generated `identity.el`; personal and work keep isolated doom overlays (no shared config
  segments). The old `configRepo` default (`personal-doom.git`) is stale; the live remote is
  `madsbv/doom.d.git`.
