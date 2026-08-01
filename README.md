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
| Desktop | NixOS (x86_64-linux) | personal | graphical workstation |
| Laptop | NixOS (x86_64-linux) | personal | graphical, portable |
| Home server(s) | NixOS (x86_64-linux / aarch64-linux) | personal | headless, `server` profile |
| Mac | nix-darwin (aarch64-darwin) | personal | personal machine |
| Work laptop | Home Manager standalone (today), nixos-wsl (next) | work | work-only config |

---

## Architecture decisions

| # | Decision | Rationale |
| --- | --- | --- |
| AD-1 | **Three-repo diamond**: `core ← personal`, `core ← work` | Work isolation is a hard requirement; both leaves share generic config without work ever seeing personal data. |
| AD-2 | **Core contains no hosts, no identity, no secrets** | Keeps core forkable/public-able, and makes the sharing boundary auditable. |
| AD-3 | **flake-parts + dendritic feature modules** | Every `.nix` file (except entry points) is a flake-parts module; features span NixOS + nix-darwin + Home Manager in one file. This is the community's answer to cross-class sharing. Modules auto-loaded with import-tree. |
| AD-4 | **Identity injection via custom `mine.*` options** | Core defines options (`mine.hostName`, `mine.user.*`, `mine.location.*`, `mine.network.tailscale.enable`, ...) with no defaults. Feature modules read `config.mine.*`. Leaves set values per host. No `specialArgs` plumbing, no personal values in core. |
| AD-5 | **Thin builder library, plus raw module exports** | Core exports both `lib.mkNixosHost` / `mkDarwinHost` / `mkHomeConfig` / `mkDeploy` (encapsulating all wiring) **and** the raw `nixosModules` / `darwinModules` / `homeManagerModules` sets, so leaves can drop to raw modules when they need to. |
| AD-6 | **Version pinning owned by core** | Leaves follow `core/nixpkgs`; core's builders reference core-pinned home-manager / nix-darwin / agenix-rekey / deploy-rs / nixos-wsl. One lock to update, no drift between personal and work. |
| AD-7 | **Secrets: agenix-rekey, per leaf** | Keeps the existing YubiKey master-key workflow. Generators + dummy-pubkey bootstrap suit home servers. Core wires the *mechanism*; each leaf owns its encrypted files, `secrets.nix`, and `rekeyed/` outputs. |
| AD-8 | **Deployment: deploy-rs, per leaf** | deploy-rs deploys NixOS **and** standalone Home Manager profiles over SSH; per-leaf `deploy` output keeps work and personal deployment fully separate. `nixos-anywhere` + disko for server bootstrap. |
| AD-9 | **nixos-wsl needs no special builder** | nixos-wsl is just a NixOS host plus `nixos-wsl.nixosModules.wsl` in `extraModules`. The work repo passes that module in when it migrates. |
| AD-10 | **Home Manager bundled everywhere it can be** | On NixOS / nix-darwin hosts Home Manager is used as an integrated module (`useGlobalPkgs`, `useUserPackages`); standalone `homeConfigurations` reuse the exact same core HM modules for the work laptop. |

---

## Core layout (planned)

```
core/
├── flake.nix                 # thin entry point; flake-parts + import-tree
├── modules/
│   ├── flake-module.nix      # registers flake-parts + auto module loader
│   ├── options.nix           # declares mine.* options (no defaults)
│   ├── agenix.nix            # wires agenix-rekey module (nixos + homeManager), rekey options
│   ├── base.nix              # composites: nixos.base / darwin.base / homeManager.base
│   ├── profiles/             # role aggregates: shell, dev, editors, desktop, server, headless
│   ├── features/             # cross-class features, one file per capability
│   │   ├── editors/          #   emacs.nix, nixvim.nix, vscode.nix
│   │   ├── dev/              #   git.nix, gh.nix, ssh.nix, direnv.nix, toolchains
│   │   ├── shell.nix         #   zsh/fish + starship + fzf/zoxide/eza/bat
│   │   ├── network.nix       #   platform-guarded network base
│   │   ├── tailscale.nix     #   nixos service + hm cli (default off)
│   │   └── desktop.nix       #   compositor/WM, platform-guarded
│   ├── nixos/                # boot, users, disko, impermanence, services (nixos-only)
│   └── darwin/               # homebrew, aerospace, system defaults (darwin-only)
├── lib/                      # builder functions + deploy integration
│   ├── mkNixosHost.nix
│   ├── mkDarwinHost.nix
│   ├── mkHomeConfig.nix
│   └── mkDeploy.nix
├── pkgs/                     # shared custom packages
├── README.md
└── PLAN.md
```

### Feature module pattern

A single feature file contributes to whichever module classes it touches. Example shape:

```nix
# modules/features/dev/git.nix
{ config, ... }:
{
  flake.modules.homeManager.git = { ... };   # reads config.mine.user.email etc.
}
```

Hosts (in leaves) compose features/profiles by importing `core.nixosModules.<x>` /
`core.homeManagerModules.<x>` through the builders, e.g.:

```nix
core.lib.mkNixosHost {
  system = "x86_64-linux";
  hostname = "aurora";
  profiles = [ core.profiles.base core.profiles.desktop core.profiles.dev ];
  modules = [ ./hosts/aurora/hardware.nix ./features/vpn.nix ];
};
```

### Identity (`mine.*`)

Core declares options such as:

- `mine.hostName`
- `mine.user.username`, `mine.user.fullName`, `mine.user.email`
- `mine.location.timezone`, `mine.location.latitude`, `mine.location.longitude`
- `mine.network.tailscale.enable`

Each leaf host supplies an `identity.nix` that sets these. Builders always prepend the options module
to every evaluation (including `home-manager.sharedModules` for nested and standalone Home Manager) so
the options are always declared. Leaves may freely override; core defaults use `lib.mkDefault`.

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
- **Formatting/linting**: `nixfmt-rfc-style`, `statix`, `deadnix`.

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
