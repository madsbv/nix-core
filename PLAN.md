# Implementation Plan

Current-state plan for the three-repo fleet described in [README.md](./README.md). Status legend:
`[ ]` todo · `[~]` in progress · `[x]` done. This file is a **plan**, not a history — past events live in
git; this records the current state and what remains.

Milestones 0–4 are complete. Milestone 5 (feature-parity restoration) is the current focus. Work that
needs specific hardware (the Mac, the servers, the work laptop) is collected in Milestone 7 so that all
hardware-independent work can land first.

---

## Milestone 0 — Bootstrap scaffolding

> Status: **done**.

Three valid, evaluable flakes in sibling directories with the right input topology: `core` declares all
inputs (nixpkgs, flake-parts, home-manager, nix-darwin, agenix-rekey, nixos-wsl, deploy-rs, agenix,
treefmt-nix, …), and the `personal`/`work` leaves declare only `core` (+ `nixpkgs.follows =
"core/nixpkgs"`).

## Milestone 1 — Core module framework

> Status: **done**.

flake-parts + dendritic skeleton: `lib/load.nix` auto-loader, the `mine.*` option namespace
(`modules/options.nix`), `modules/base.nix` composites (`nixos.base` / `darwin.base` / `homeManager.base`),
representative feature modules (git/ssh/shell), and the host builders `lib/mkNixosHost.nix`,
`lib/mkDarwinHost.nix`, `lib/mkHomeConfig.nix`, `lib/mkDeploy.nix` (now auto-discovered flake-parts
modules that self-register on `config.flake.lib`).

## Milestone 2 — Feature set (development tooling)

> Status: **done**.

Shared development-tooling modules: editors (emacs, nixvim), `features/dev/*` toolchains (fortran, git, gh,
go, java, javascript, lua, nix, python, R, rust, shell, tools), `features/shell.nix` (zsh + starship +
fzf/zoxide/eza/bat), `features/terminal.nix` (alacritty), tailscale, yubikey, and the
`base`/`shell`/`dev`/`editors`/`terminal` profiles.

## Milestone 3 — Personal repo, secrets, deployment

> Status: **done**.

Personal-bound features ported (librewolf, dropbox, restic, wifi, protonvpn, email, zathura, desktop,
awesomewm, darwin stack), all five hosts (`mbv-workstation`, `mbv-desktop`, `mbv-xps13`, `hp-90`,
`mbv-mba`) build and pass `nix flake check`, `deploy.nix` via `mkDeploy`, agenix-rekey with committed
`rekeyed/`, and the `justfile`. Remaining secrets/host details discovered during the parity audit now live
in Milestone 5.

## Milestone 4 — nix-darwin host

> Status: **done**.

`lib/mkDarwinHost.nix` completed, `core/modules/darwin/homebrew.nix` (nix-homebrew), platform-guard audit
(`users.nix` split into `users-darwin.nix`, NixOS-only system modules removed from `darwin.base`),
`mbv-mba` evaluates to a `darwinSystem` derivation. Real switch/deploy on hardware is Milestone 7.

---

## Milestone 5 — Feature-parity restoration

> Status: **in progress** (current focus).

Goal: close every gap between the old `/etc/nixos/nix` config and the new fleet, per the parity audit.
Grouped into five sub-steps; each item is one checklist entry.

### P1 — Core inputs & nix settings

- [ ] Port the `nix.*` settings block, synchronized across NixOS / nix-darwin / Home Manager where
      sensible: `substituters` + `trusted-public-keys` (`nix-community.cachix.org`, `cache.garnix.io`,
      `numtide.cachix.org`), `experimental-features` (incl. `ca-derivations`, `recursive-nix`,
      `fetch-closure`, `blake3-hashes`, `auto-allocate-uids`, `cgroups`), `nix.gc` (weekly
      `--delete-older-than 30d`), `optimise.automatic`, `trusted-users`, `download-buffer-size`, `sandbox`,
      `keep-going`, `show-trace`, `warn-dirty = false`, `max-free`/`min-free`. Declare under `mine.*` so the
      HM identity mirror carries them. (Nix version / sandbox-security concerns are out of scope.)
- [ ] Tie global `nixpkgs.config.allowUnfree = true` into this settings work (replaces the old global
      setting; per-host overrides may remain).
- [ ] Add `hosts` (StevenBlack) as a core input and wire the `/etc/hosts` blocklist into all NixOS systems
      and nix-darwin if feasible (analyze the darwin path; Home Manager cannot control `/etc/hosts`).
- [ ] Add `nox` (`nix-options-search`) as a core input and install it on all hosts.
- [ ] Add `nix-auth` back to the core devShell.
- [ ] Introduce an overlays mechanism in core (auto-loaded `overlays/` dir or explicit `nixpkgs.overlays`)
      and port the `xdg-user-dirs-darwin` patch (compile fix pulled in by xdg-utils → alacritty on Darwin).
- [ ] Set `preferXdgDirectories = true` on all system types (first verify whether it is now the
      Home Manager default).

### P2 — System packages & tooling

- [ ] Restore the system-wide package list (bash-completion, btop, htop, iftop, ripgrep, jq, yq, yazi,
      zellij, nix-tree, nix-melt, rage, libfido2, parallel-full, watchexec, gdu, lsof, sqlite, curlFull,
      wget, zip, zstd, unrar, unzip, …). Placement is an open design choice: a single system-packages
      module vs. folding packages into the relevant features.
- [ ] Analyze which terminfo packages are actually still needed (kitty/wezterm/ghostty may be droppable now
      that kitty is removed).
- [ ] Add tracing (`programs.bcc`, `programs.sysdig`, `strace`, `perf`) as a dev module (new or existing).
- [ ] Add `libvirtd` (qemu `swtpm`, `virtiofsd`) to the virtualization feature. Do **not** add podman.

### P3 — Shell & terminal

- [ ] Shell: port the dropped pieces — zsh plugins (vi-mode, autocomplete, autosuggestion), the custom
      aliases (`gj j ls l less cat grep psgrep wget f fj`), `yazi` + `zellij` + `nix-index`, `bat` theme +
      `bat-extras`, sessionVariables (`LESSHISTFILE`, `WGETRC`, `ZDOTDIR`, `ZSH_CACHE`), zsh options
      (`autocd`, `dotDir`, `history.*`), and the global `gitignore_global` + git settings
      (`credential.helper`, `rebase.autoStash`, `core.editor`).
- [ ] Add a starship config roughly replicating the old powerlevel10k prompt.
- [ ] Terminal: fully remove kitty (and wezterm), keep alacritty only, port the base16 color scheme, and
      ensure the old Nerd Font is available.
- [ ] Neovim: set `vimdiffAlias`, add `gcc` to extraPackages, and add the treesitter grammars (the old
      minimal `nvim-config` is a deliberate drop — see Deliberate omissions).

### P4 — Dev & editor parity

- [ ] Rust: restore the bacon `clippy-fix`/`semver-checks` jobs + keybindings, `cargo-diet`/`cargo-msrv`/
      `cargo-semver-checks`, `~/.cargo/config.toml` (aliases, `build.target-dir`, `incremental`,
      `future-incompat-report`, `net.git-fetch-with-cli`), and the darwin `LIBRARY_PATH` (libiconv) fix.
- [ ] Restore small package/config drops: `ty` (python), `CGO_ENABLED = "0"` (go), the lua LSP session var
      (or move it into the `identity.nix`/`identity.el` machinery), `vscode-langservers-extracted` (tools),
      and the RStudio `hunspellDicts = {}` override.
- [ ] Emacs: verify whether the old build flags (SQLite/WebP/ImageMagick/TreeSitter/NativeComp) are now
      defaults; port the **actually-used** emacs package + patch set (on darwin: generic emacs + `withPgtk`
      + the `fix-window-role` / `round-undecorated-frame` / `system-appearance` patches).
- [ ] SSH: analyze the dropped `openssh` package pin and agenix `IdentityFile` wiring and decide whether to
      restore them (explicitly needs later analysis).
- [ ] Email: restore enough context to rebuild a functioning email system, fix the easy parts of the new
      declarative `accounts.email` config, and document the remaining differences in the plan.

### P5 — Personal hosts & secrets

- [ ] Wire the yubikey feature (`services.yubikey-agent` + `yubikey-manager`) into `mbv-workstation` and
      `mbv-mba`.
- [ ] `mbv-workstation`: fill in the deploy-rs root `authorizedKeys` (currently an empty `TODO`).
- [ ] restic: set `mine.restic.exclude` (ollama, libvirt/images, Steam, Downloads, `.cache`), set
      `persistCache = true`, and verify the healthchecks `.age` file was moved to `secrets/restic/`.
- [ ] transmission: restore `watch-dir-enabled`, `rpc-bind-address`, `rpc-host-whitelist`.
- [ ] home-assistant: port the appdaemon `equalize_attributes.toml`.
- [ ] Persistence: add `/etc/nixos`, `/var/log`, `/var/lib`, and
      `fileSystems."/nix/persist/home".neededForBoot = true`.
- [ ] extraGroups: move the `docker` group into the docker feature and `networkmanager` into the networking
      feature (only `wheel` is currently auto-added); analyze whether the old `home-manager.users.root`
      sharedModules wiring is still needed.
- [ ] `mbv-mba`: set dock entries + `mine.darwin.dock.user`; add `trusted-users = ["@admin"]` +
      `nix.daemonIOLowPriority` (tie into P1); reproduce `knownNetworkServices` + hostname/computerName;
      wire the svim blacklist via `xdg.configFile`; replace kitty references with alacritty.
- [ ] Port the common-packages list (pandoc, texliveFull, imagemagick, graphviz, portaudio, multimarkdown,
      stylelint, texlab, djvulibre, poppler, pdfarranger, languagetool, enchant, bibutils, fontconfig,
      hunspell, xsel, ffmpeg, and the extra aspell dicts). Placement is an open design choice.
- [ ] Port the NixOS desktop user packages (signal-desktop, libreoffice-qt, hunspell + dicts, flameshot)
      into a desktop/user preset or directly into `mbv-workstation`.

---

## Milestone 6 — Hardening, CI, polish

> Status: **not started** (follows parity so tests lock in the final state).

- [x] `nixfmt` + statix + deadnix configured (via treefmt) and passing in all three repos.
- [~] CI (`nix flake check`) per repo — core workflow is in place; leaf CI is pending repo hosting (leaf
      workflows must check out core and run `--override-input core path:<checkout>`).
- [ ] Namaka snapshot tests across core + personal + work for representative modules and host configs.
- [~] Stub-input pattern in core so public CI never requires private inputs — deferred (all current core
      inputs are public); revisit when a private input is added.
- [x] Document `--override-input core path:../core` in each leaf README.

---

## Milestone 7 — Hardware-dependent bring-up

> Status: **not started** (requires the Mac, the physical servers, and the work laptop).

- [ ] Deploy/switch `mbv-mba` on real hardware (rekey + `darwin-rebuild switch --flake .#mbv-mba` or
      deploy-rs) and verify a core feature behaves identically on the Mac and on NixOS.
- [ ] Server bootstrap: `nixos-anywhere` + disko from a fresh state on the physical servers, then rekey for
      the real host keys.
- [ ] **Work repo completion**:
  - [ ] `work/features/` (work-specific programs, policies, VPN).
  - [ ] `work/secrets/` (agenix-rekey with a plain, non-YubiKey age master key).
  - [ ] `work/deploy.nix` + `justfile`.
  - [ ] Isolation audit: input graph is exactly `{core, nixpkgs → core}`; tailscale never imported; no
        personal references (`rg` / `nix eval`).
  - [ ] nixos-wsl migration: add `nixos-wsl.nixosModules.wsl` and switch `mkHomeConfig` → `mkNixosHost`,
        keeping the HM-only profile available during the transition.

---

## Deliberate omissions

Features from the old config that are intentionally **not** carried over. Documented so future agents don't
"fix" them back.

| Omitted | Replacement / rationale |
| --- | --- |
| `system.autoUpgrade` (enable) | Replaced by the `prefetch` mechanism (`nix flake update --commit-lock-file` + build on a timer). |
| powerlevel10k | Replaced by starship (with a config roughly matching the old p10k prompt). |
| kitty / wezterm | Replaced by an alacritty-only terminal feature. |
| Old minimal neovim config | Deliberately dropped; keep `vimdiffAlias` + `gcc` + treesitter grammars only. |
| podman | Dropped; keep docker + libvirtd. |
| bitwarden-cli | Dropped (`bitwarden-desktop` / the mac cask remain). |
| `extrauser.nix` (gameruser specialisation) | Dropped. |
| `overclocking.nix` | Dropped (file was empty; amdgpu overdrive + lact + gamemode are already ported). |
| `permittedInsecurePackages = ["electron-39.8.10"]` | Dropped. |
| fenix | Replaced by oxalica rust-overlay. |
| karabiner-elements custom derivation | Replaced by nix-darwin `services.karabiner-elements`. |
| Remote-builder feature | Dropped as-is (see Deferred reimplementation). |
| Inactive overlays (`spacefm`, `cargo-instruments`, `dbdcsv`) | Never wired in the old config; dropped. |

## Deferred reimplementation

Features worth having later, but not worth porting as-is. Recorded with enough detail to rebuild them
cleanly.

- **Remote builders** (old `local.builder`): Tailscale-based remote Nix builders — a `builder` user,
  `nix.buildMachines` over the tailnet, and `enableLocalBuilder`. It never worked well and needs a redesign;
  the *purpose* (offload builds to faster fleet machines over Tailscale) is worth preserving.
- **Ephemeral installer / ISO** (old `hosts/ephemeral` + `nixos-generators`): a bootstrapping installer
  built with disko + impermanence, a `zpool` bootstrap + `nixos-install --flake` script, `persist.nix`, and
  a Tailscale auth file. Recreate a cleaner version later on top of core's disko/impermanence wiring.
- **File manager**: the old spacefm overlay (with a gcc14 patch) was never actually installed. Decide
  between resurrecting spacefm or an alternative (thunar/pcmanfm/…; `yazi` already covers the CLI case),
  and re-check whether the gcc14 patch is still required.
- **Full neovim config**: the old setup pulled its real config from a separate `madsbv/nvim-config` repo
  (Supermaven + treesitter + Lua keymaps). Re-port it properly into nixvim later.

---

## Decisions recorded (confirmed with the operator)

- **Hostnames stay `mbv-*`** — preserves host keys, `rekeyed/` paths, deploy-rs config, tailnet identity,
  and DNS.
- **No dedicated laptop** — current fleet is desktop + 3 servers + Mac; `lapis` is reserved. The `laptop`
  feature is personal and used by `mbv-workstation` and `mbv-xps13`.
- **Work repo is green-field** — nothing migrates into `work` except shared `core` features.
- **Color-scheme goes to core** — base16 wiring + the `molokai` scheme are generic theming.
- **`keys/builder_ed25519` stays tracked** — it is the macOS linux-builder VM key, not security-sensitive.
- **Import-gating is the module pattern** — importing a module activates it unconditionally; disabling means
  not importing. (The enable-gated modules were converted in M3.)
- **Doom config is nix-managed as a store-built `$DOOMDIR`** (Option 3, below).

## Doomemacs — Option 3: store-built DOOMDIR

The doom config is nix-managed end to end. A single derivation (`lib/mkDoomdir.nix`) composes the whole
`$DOOMDIR` from core's shared doom tree + the active leaf's overlay and materializes it in the store;
`~/.config/doom` is a symlink to the store result. `~/.config/emacs` remains a live `git clone` of
doomemacs/core + `bin/doom install` (needed for `doom sync` version derivation).

- **Layering** happens inside the derivation: core `config.el`/`packages.el` end with
  `(load! "config-extra" (doom-user-dir))`; the leaf fragments are copied alongside. `modules/` is the
  union of core + leaf dirs (leaf wins on collision). `init.el` = `core/doom/init.el` ++ `leaf/init-extra.el`
  (two idempotent `doom!` blocks). `identity.el` is generated from a minimal `mine.*` eval.
- **Identity extraction** uses a standalone `lib.evalModules` run importing `modules/options.nix` + the
  host's `identity.nix` (~100 ms), avoiding a full host eval.
- **Flake surface**: `flake.doomdirs.<host>` (lazy attr) → `nix build .#doomdirs.<host>`.
- **Read-only redirects**: core `config.el` sends `custom-file`, `custom-theme-directory`, and
  transient/history writes to `$XDG_STATE_HOME`; `snippets/`/`autoload/` are baked read-only.
- **Workflow**: `just doomdir` rebuilds + relinks + runs `doom sync` (fast, ~1–4 s), and `just
  doomdir-build` builds to `/tmp` without touching the live link. Elisp edits can be evaluated live in a
  running Emacs.

## Migration reference

Operational facts from the old repo that still matter:

- **WiFi secret renames** (verify the `.age` files exist under the new names): `spiderlan-nm` →
  `wifi-spiderlan`, `att-nm` → `wifi-att`, `synapse-nm` → `wifi-synapse`, `vindbjerggaard` →
  `wifi-vindbjerggaard`.
- **ProtonVPN secret**: `mbv-desktop-protonvpn` → `protonvpn-wg`.
- **Email secrets** (`mbsyncrc`, `mu-init-addresses`, `pmbridge-password`) are declared in
  `personal/features/email/secrets.nix`, but `mbsyncrc` is no longer consumed (email now uses declarative
  `accounts.email`).
- **restic healthchecks secret** moved `secrets/other/` → `secrets/restic/` — verify the `.age` file was
  relocated (Milestone 5 P5).
- **`keys/builder_ed25519`** stays tracked.
- **`ephemeral` host** is intentionally not ported (see Deferred reimplementation).

---

## Verification commands

```bash
# core
cd core && nix flake check && nix flake show

# leaf (personal / work)
cd personal && nix flake check
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
nix build .#homeConfigurations.<user>.activationPackage
nix run nixpkgs#nixos-rebuild -- build --flake .#<host>

# secrets (requires YubiKey)
cd personal && agenix edit <name> && agenix rekey --flake . && just deploy <node>

# dev loop against a local core checkout
nixos-rebuild switch --flake .#<host> --override-input core path:../core
```
