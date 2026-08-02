# nix-core

Shared, platform-neutral Nix modules and builders for a multi-host, multi-platform Nix fleet.

`nix-core` is the **shared core** of a three-repo configuration split. It contains generic program and
environment configuration that is reused verbatim across every machine type — NixOS, nix-darwin,
standalone Home Manager, and nixos-wsl — and across the personal and work deployments.

It deliberately contains **no hosts, no identity, and no secrets**. Those live in the two leaf
repositories.

---

## Goal

Manage a heterogeneous fleet declaratively:

- **Personal**: a NixOS desktop, a NixOS laptop, one or more NixOS home servers, and a nix-darwin Mac.
- **Work**: a work laptop that today runs standalone Home Manager (inside WSL) and will migrate to
  nixos-wsl.

with:

1. Maximum configuration sharing across all four system types.
2. Heavy reuse of development-tool configuration (emacs/vim/IDE, shells, git, toolchains) across all
   machines.
3. Tailscale/VPN and hostname sharing between personal machines and home servers — but **never** with
   the work laptop.
4. Built-in secrets management (agenix-rekey, master key on a YubiKey) with per-repository secret
   stores.
5. Remote deployment of multiple machines (deploy-rs), kept separate between work and personal.
6. A hard requirement that the work laptop supports additional configuration **on top of** the shared
   core, managed in a **separate git repository** that never sees personal data.

---

## Repository topology

```
        ┌─────────────────────────────┐
        │  nix-core                   │  git repo 1 — generic modules + builders
        │  feature modules, options,  │  no hosts, no identity, no secrets
        │  profiles, builders, pkgs   │
        └────────────┬────────────────┘
                     │ git flake input (nixpkgs.follows)
        ┌────────────┴──────────────┐
┌───────┴────────┐          ┌───────┴───────────┐
│ personal       │          │ work              │  git repo 3 — private
│ git repo 2     │          │ git repo 3        │
│ NixOS desktop  │          │ work laptop       │
│ NixOS laptop   │          │  HM-only today,   │
│ home servers   │          │  nixos-wsl next,  │
│ nix-darwin Mac │          │ work identity +   │
│ personal       │          │ work secrets      │
│ identity+secret│          └───────────────────┘
└────────────────┘
```

- **`core`** pins the full toolchain (nixpkgs, home-manager, nix-darwin, agenix-rekey, nixos-wsl,
  deploy-rs) in its own `flake.lock` and exposes modules and builder functions.
- **`personal`** and **`work`** are independent flakes whose **only** upstream input is `core`. Their
  own `nixpkgs` follows `core/nixpkgs`; their home-manager / nix-darwin / agenix-rekey / deploy-rs
  versions are the ones core pins, used transitively through core's builders.
- **Work never depends on personal** and personal never depends on work. Isolation is structural, not
  negotiated at runtime.

### Machine inventory

| Machine | Platform | Repo | Notes |
| --- | --- | --- | --- |
| `mbv-workstation` | NixOS (x86_64-linux) | personal | graphical workstation |
| `mbv-desktop` | NixOS (x86_64-linux) | personal | media server + CUDA |
| `mbv-xps13` / `hp-90` | NixOS (x86_64-linux) | personal | headless laptop-servers, `server` profile |
| `mbv-mba` | nix-darwin (aarch64-darwin) | personal | personal machine |
| Work laptop | Home Manager standalone (today), nixos-wsl (next) | work | work-only config |

No dedicated laptop is planned; `lapis` is reserved for a future machine. Hostnames are kept as-is to
preserve host keys, `rekeyed/` paths, deploy-rs config, tailnet identity, and DNS (see the migration
notes in PLAN.md).

---

## Architecture decisions

| # | Decision | Rationale |
| --- | --- | --- |
| AD-1 | **Three-repo diamond**: `core ← personal`, `core ← work` | Work isolation is a hard requirement; both leaves share generic config without work ever seeing personal data. |
| AD-2 | **Core contains no hosts, no identity, no secrets** | Keeps core forkable/public-able, and makes the sharing boundary auditable. |
| AD-3 | **flake-parts + dendritic feature modules** | Every `.nix` file (except entry points) is a flake-parts module; features span NixOS + nix-darwin + Home Manager in one file. This is the community's answer to cross-class sharing. Modules auto-loaded with import-tree. |
| AD-4 | **Identity injection via custom `mine.*` options** | Core defines options (`mine.hostName`, `mine.primaryUser`, `mine.users`, `mine.location.*`, `mine.network.tailscale.enable`, ...) with no defaults. `mine.user` is derived from the primary user; feature modules read `config.mine.*`. Leaves set values per host. No `specialArgs` plumbing, no personal values in core. |
| AD-5 | **Thin builder library, plus class-keyed module registry** | Core exports the builders (`config.flake.lib.mkNixosHost` / `mkDarwinHost` / `mkHomeConfig` / `mkDeploy`, encapsulating all wiring) **and** the per-class module registry (`config.flake.modules.{nixos,homeManager,darwin}.*`), so leaves can drop to raw modules when they need to. |
| AD-6 | **Version pinning owned by core** | Leaves follow `core/nixpkgs`; core's builders reference core-pinned home-manager / nix-darwin / agenix-rekey / deploy-rs / nixos-wsl. One lock to update, no drift between personal and work. |
| AD-7 | **Secrets: agenix-rekey, per leaf** | Keeps the existing YubiKey master-key workflow. Generators + dummy-pubkey bootstrap suit home servers. Core wires the *mechanism*; each leaf owns its encrypted files, `secrets.nix`, and `rekeyed/` outputs. |
| AD-8 | **Deployment: deploy-rs, per leaf** | deploy-rs deploys NixOS **and** standalone Home Manager profiles over SSH; per-leaf `deploy` output keeps work and personal deployment fully separate. `nixos-anywhere` + disko for server bootstrap. |
| AD-9 | **nixos-wsl needs no special builder** | nixos-wsl is just a NixOS host plus `nixos-wsl.nixosModules.wsl` in `extraModules`. The work repo passes that module in when it migrates. |
| AD-10 | **Home Manager bundled everywhere it can be** | On NixOS / nix-darwin hosts Home Manager is used as an integrated module (`useGlobalPkgs`, `useUserPackages`); standalone `homeConfigurations` reuse the exact same core HM modules for the work laptop. |

---

## Core layout

```
core/
├── flake.nix                 # thin entry point; flake-parts + curried framework/devShell
├── modules/
│   ├── flake-module.nix      # framework: flake-parts + auto-loader + builder discovery
│   ├── options.nix           # declares mine.* options (no defaults)
│   ├── agenix.nix            # agenix(-rekey) wiring, per class (nixos + homeManager + darwin)
│   ├── base.nix              # composites: nixos.base / darwin.base / homeManager.base
│   ├── color-scheme.nix      # base16 nixos/homeManager/darwin modules, default molokai
│   ├── treefmt.nix           # nixfmt / statix / deadnix, wired into `nix flake check`
│   ├── devShell.nix          # core dev shell (curried over core's inputs)
│   ├── _hm-mirror.nix        # helper: prune-based identity mirror for Home Manager evals
│   ├── profiles/             # role aggregates: base, shell, dev (class-keyed modules)
│   ├── features/             # cross-class features, one file per capability
│   │   ├── editors/          #   emacs.nix, nixvim.nix
│   │   ├── dev/              #   git.nix, gh.nix, ssh.nix, direnv.nix, toolchains
│   │   ├── shell.nix         #   zsh/fish + starship + fzf/zoxide/eza/bat
│   │   ├── tailscale.nix     #   nixos service + hm cli (default off)
│   │   ├── yubikey.nix       #   (migration M2)
│   │   ├── laptop.nix        #   reserved for a future laptop (migration M2)
│   │   └── desktop.nix       #   generic desktop bits, platform-guarded
│   ├── system/               # keys, builder, users framework, update-diff, register-flake, ...
│   └── nixos/                # nixos-only: base.nix (networking/firewall/openssh/zfs/...)
│   ├── darwin/               # darwin-only: homebrew.nix (nix-homebrew wiring)
├── lib/                      # builder functions + deploy integration (auto-discovered)
│   ├── load.nix              # import-tree auto-loader (excluded from builder discovery)
│   ├── mkNixosHost.nix       # registered as config.flake.lib.mkNixosHost
│   ├── mkDarwinHost.nix      # registered as config.flake.lib.mkDarwinHost
│   ├── mkHomeConfig.nix      # registered as config.flake.lib.mkHomeConfig
│   └── mkDeploy.nix          # registered as config.flake.lib.mkDeploy
├── pkgs/                     # shared custom packages
├── README.md
└── PLAN.md
```

All `.nix` files under `lib/` (except `load.nix`) are auto-discovered builder modules — adding a
new builder file is all it takes to register it on `config.flake.lib`. Core's pinned flake inputs
are re-exported as `config.flake.inputs`, so leaves can reference transitive inputs (e.g.
`config.flake.inputs.disko.nixosModules.disko`) without declaring them.

### Feature module pattern

A single feature file contributes to whichever module classes it touches. Example shape:

```nix
# modules/features/dev/git.nix
{ config, ... }:
{
  flake.modules.homeManager.git = { ... };   # reads config.mine.user.email etc.
}
```

Leaves consume the framework by importing `core.flakeModules.default`, then compose profiles/features
through the builders from `config.flake.*`. The leaf entry point:

```nix
# personal/flake.nix (leaf entry point)
outputs = inputs@{ self, core, flake-parts, ... }:
  flake-parts.lib.mkFlake { inherit inputs; } {
    imports = [ core.flakeModules.default ./hosts ];
  };
```

Hosts then compose class-keyed profiles and features, e.g.:

```nix
# personal/hosts/mbv-workstation/default.nix
{ config, ... }:
{
  flake.nixosConfigurations.mbv-workstation = config.flake.lib.mkNixosHost {
    system = "x86_64-linux";
    hostname = "mbv-workstation";
    profiles = [
      config.flake.profiles.base
      config.flake.profiles.desktop
      config.flake.profiles.dev
    ];
    modules = [ ./hardware.nix ../features/vpn.nix ];
    identity = [ ./identity.nix ];
  };
}
```

### Identity (`mine.*`)

Core declares options such as:

- `mine.hostName`
- `mine.primaryUser` — picks the primary user from `mine.users`
- `mine.users` — attrset keyed by username; per-user `username`, `fullName`, `email`, `isSystemUser`,
  `uid`, `gid` (darwin-only), `shell`, `extraGroups`, `sshAuthorizedKeys`, `initialHashedPassword`,
  `homeManagerModules`
- `mine.user` — derived alias of `mine.users.<primaryUser>`; inside a Home Manager evaluation it
  resolves to the *current* user
- `mine.location.timezone`, `mine.location.latitude`, `mine.location.longitude`
- `mine.network.tailscale.enable`
- `mine.system.stateVersion` — per-host NixOS/Home Manager stateVersion override; when unset core falls
  back to its default (`25.05`) and warns at build time. Set it per host so upgrades are intentional.

Each leaf host supplies an `identity.nix` that sets these. The users framework
(`modules/system/users.nix`) turns `mine.users` into NixOS users and per-user Home Manager configs:
non-system users get `wheel` and their own HM config (separate browser/WM/desktop per user), system
users become robot/service accounts (locked shell, key-only SSH). Every evaluation gets the options
module via the per-class base composite (`config.flake.modules.{nixos,homeManager,darwin}.base`), which
the builders include by default in both integrated and standalone Home Manager — no `specialArgs` or
`sharedModules` plumbing. Leaves may freely override; core defaults use `lib.mkDefault`.

### Secrets flow (agenix-rekey)

- Each leaf has `secrets/secrets.nix` (rekey options: `masterIdentities`, per-host `hostPubkey`,
  `storageMode = "local"`, `localStorageDir`), encrypted `.age` files, and a **committed** `rekeyed/`
  output directory (keeps builds pure, works with deploy-rs and CI).
- Personal and work each hold their own secret store; they may share the same YubiKey master identity
  (same human operator).
- Servers use **generators** (WireGuard private keys, service passwords, htpasswd) and **dummy-pubkey
  bootstrap** for brand-new hosts.
- Workflow: `agenix edit <name>` → commit → `agenix rekey --flake .` (YubiKey) → build/deploy.

### Deployment flow

- `just deploy <node>` runs `agenix rekey` then `deploy-rs .#<node>`.
- Fresh home server: `nixos-anywhere` + disko (from the core `server` profile), then rekey for the real
  host key and `deploy-rs`.
- The work laptop (HM-only today) is deployed as a Home Manager profile; after migration it is a
  NixOS (nixos-wsl) profile.

---

## Work isolation (audit checklist)

- [ ] Work's flake input graph is exactly `{ nixpkgs (→ core), core }`. Nothing personal.
- [ ] `mine.network.tailscale.enable` defaults to `false`; work never enables it and defines its own
      VPN feature in the work repo.
- [ ] Git/editor/dev modules in core are value-driven by `mine.*`; work and personal get correct
      identities with zero cross-repo data.
- [ ] Core git history contains no identity, hostnames, or secrets.

---

## Development workflow

- **Update core in a leaf**: `nix flake update core` (or `nix flake lock --update-input core`).
- **Local dev loop against core**: `--override-input core path:../core` on any build/deploy command.
- **Check**: `nix flake check` in each repo. Core is checkable without any secrets; leaves build the
  already-rekeyed `rekeyed/` outputs, so builds stay pure.
- **Formatting/linting**: `nixfmt` (RFC style), `statix`, `deadnix`.

### Known friction

- **Git-input refresh lag**: core changes need a lock update in leaves; the local `--override-input`
  loop avoids the wait during development.
- **Home Manager on raw Windows is not supported**: the HM-only work config runs inside WSL, which is
  consistent with the nixos-wsl migration.
- **Dendritic module debugging**: use `nixos-option` / `nix eval` rather than grepping; `mine.*` is the
  single source of truth.
- **Priority discipline**: core defaults use `lib.mkDefault`; leaves override freely with
  `lib.mkForce` only as an escape hatch.

See [PLAN.md](./PLAN.md) for the detailed implementation plan.
