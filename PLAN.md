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

> Status: **done** (SSH deliberately deferred to a later analysis; see P4).

Goal: close every gap between the old `/etc/nixos/nix` config and the new fleet, per the parity audit.
Grouped into five sub-steps; each item is one checklist entry.

### P1 — Core inputs & nix settings

- [x] Port the `nix.*` settings block, synchronized across NixOS / nix-darwin / Home Manager where
      sensible: `substituters` + `trusted-public-keys` (`nix-community.cachix.org`, `cache.garnix.io`,
      `numtide.cachix.org`), `experimental-features` (incl. `ca-derivations`, `recursive-nix`,
      `fetch-closure`, `blake3-hashes`, `auto-allocate-uids`, `cgroups`), `nix.gc` (weekly
      `--delete-older-than 30d`), `optimise.automatic`, `trusted-users`, `download-buffer-size`, `sandbox`,
      `keep-going`, `show-trace`, `warn-dirty = false`, `max-free`/`min-free`. Declared under `mine.nix.*`
      (single `mine.nix.settings` attrset + `allowUnfree`/`gc`/`optimise` knobs) so the HM identity mirror
      carries them. (Nix version / sandbox-security concerns are out of scope.)
- [x] Tie global `nixpkgs.config.allowUnfree = true` into this settings work (replaces the old global
      setting; per-host overrides may remain). On integrated hosts it is set on the OS nixpkgs; on
      standalone Home Manager (no OS) it is set in the HM eval, guarded by `!submoduleSupport.enable`.
- [x] Add `hosts` (StevenBlack) as a core input and wire the `/etc/hosts` blocklist into all NixOS systems
      and nix-darwin (NixOS via `hosts.nixosModule` + `networking.stevenBlackHosts.enable`; darwin via
      `environment.etc."hosts"` since nix-darwin has no `networking.extraHosts`). Home Manager cannot
      control `/etc/hosts`.
- [x] Add `nox` (`nix-options-search`) as a core input and install it on all hosts (Home Manager
      `home.packages` via the base composite).
- [x] Add `nix-auth` back to the core devShell.
- [x] Overlays: **selective, not auto-loaded** (operator decision) — the `xdg-user-dirs-darwin` patch
      (compile fix pulled in by xdg-utils → alacritty on Darwin) is defined and applied in the terminal
      feature's darwin module (`nixpkgs.overlays`), not a global `overlays/` dir.
- [x] Set `preferXdgDirectories = true` on all system types (verified: it is still *not* the Home Manager
      default, so core sets it in `homeManager.base`).

### P2 — System packages & tooling

- [x] Restore the system-wide package list, distributed to the features that own them: the general
      utilities live in a new `features/system/cli-tools.nix` (base profile, all three classes —
      `environment.systemPackages` on NixOS/darwin + `home.packages` for HM-only), `nix-tree`/`nix-melt`
      in `features/dev/nix.nix` (also system-wide on NixOS), `libfido2` in `features/yubikey.nix`, and
      `yazi`/`zellij`/`nix-index` in the shell feature (P3).
- [x] Analyze terminfo packages: none are still needed — alacritty ships its own terminfo and
      kitty/wezterm/ghostty are gone. No terminfo package is installed.
- [x] Add tracing (`programs.bcc`, `programs.sysdig`, `strace`, `perf`) as a new `features/dev/tracing.nix`
      (NixOS only).
- [x] Add `libvirtd` (qemu `swtpm`, `virtiofsd`) to the virtualization feature. No podman.

### P3 — Shell & terminal

- [x] Shell: port the dropped pieces — zsh plugins (vi-mode, autocomplete, autosuggestion), the custom
      aliases (`gj j ls l less cat grep psgrep wget f fj`), `yazi` + `zellij` + `nix-index`, `bat` theme +
      `bat-extras`, sessionVariables (`LESSHISTFILE`, `WGETRC`, `ZDOTDIR`, `ZSH_CACHE`), zsh options
      (`autocd`, `dotDir`, `history.*`), and the global `gitignore_global` + git settings
      (`credential.helper`, `rebase.autoStash`, `core.editor`). Aliases are consolidated in
      `programs.zsh.shellAliases` (`.zshrc`), which also fixes the old nix-darwin/zellij `.zprofile` issue.
- [x] Add a starship config roughly replicating the old powerlevel10k prompt (two-line layout: dir + git +
      right-aligned status/duration/jobs/languages, then the prompt char).
- [x] Terminal: fully remove kitty (and wezterm), keep alacritty only, port the base16 color scheme (from
      `config.scheme.withHashtag`), and use the old Nerd Font (`MesloLGS NF`, already in the fonts feature).
- [x] Neovim: enable treesitter via nixvim's native `plugins.treesitter` (all grammars by default), add
      `gcc` via `extraPackages`, and provide `vimdiff` as a shell alias (`nvim -d`) since nixvim has no
      native `vimdiffAlias` option.

### P4 — Dev & editor parity

- [x] Rust: restore the bacon `clippy-fix`/`semver-checks` jobs + keybindings, `cargo-diet`/`cargo-msrv`/
      `cargo-semver-checks`, `~/.cargo/config.toml` (aliases, `build.target-dir`, `incremental`,
      `future-incompat-report`, `net.git-fetch-with-cli`), and the darwin `LIBRARY_PATH` (libiconv) fix.
- [x] Restore small package/config drops: `ty` (python), `CGO_ENABLED = "0"` (go), the lua LSP session var
      (`LUA_LANGUAGE_SERVER_INSTALL_DIR`, kept in the lua feature), `vscode-langservers-extracted` (tools),
      and the RStudio `hunspellDicts = {}` override.
- [x] Emacs: verified nixpkgs defaults — `withSQLite3`/`withWebP`/`withTreeSitter`/`withNativeCompilation`
      are now defaults; only `withImageMagick` (still default-off) needs an explicit `override`. On darwin,
      generic emacs + the `fix-window-role` / `round-undecorated-frame` / `system-appearance` patches (no
      `withPgtk`, which is Linux-only). `pkgs.emacs` is wrapped via `.pkgs.withPackages`.
- [x] SSH: **deferred** (operator decision) — the current minimal ssh module stays; the dropped `openssh`
      package pin and agenix `IdentityFile` wiring are recorded here for later analysis, not restored now.
- [x] Email: the declarative `accounts.email` config is complete (ProtonMail Bridge + mbsync + mu +
      imapnotify, ports 1143/1025, `realName` now derived from `mine.user.fullName`). The `mbsyncrc`
      secret is now unused (declarative `accounts.email.mbsync` replaces it) — see Migration reference.

### P5 — Personal hosts & secrets

- [x] Wire the yubikey feature (`services.yubikey-agent` + `yubikey-manager`) into `mbv-workstation` and
      `mbv-mba`. The core darwin yubikey module was fixed in the process: nix-darwin has no
      `services.yubikey-agent` (the agent runs via Home Manager's `services.yubikey-agent`, launchd), and
      `yubioath-flutter` is unavailable on Darwin (homebrew `yubico-authenticator` covers it).
- [x] `mbv-workstation`: fill in the deploy-rs root `authorizedKeys` (the user SSH pubkey).
- [x] restic: set `mine.restic.exclude` (ollama, libvirt/images, Steam, Downloads; `.cache` is already
      always excluded) and `persistCache = true` as defaults in the restic feature. The healthchecks `.age`
      file is confirmed present under `secrets/restic/`.
- [x] transmission: restore `watch-dir-enabled`, `rpc-bind-address`, `rpc-host-whitelist`.
- [x] home-assistant: port the appdaemon `equalize_attributes.toml` (the `.py` was already ported).
- [x] Persistence: add `/etc/nixos`, `/var/log`, `/var/lib` to the core persistence dirs and
      `fileSystems."/nix/persist/home".neededForBoot = true` to `znix-disk.nix`.
- [x] extraGroups: the `docker` group is added by the docker feature and `networkmanager` by the networking
      feature (only `wheel` was auto-added before). **Analysis**: the old `home-manager.users.root`
      sharedModules wiring is *not* needed — root gets CLI tools via `environment.systemPackages`
      (cli-tools feature), so no root Home Manager config is required.
- [x] `mbv-mba`: dock entries + `mine.darwin.dock.user`; `trusted-users = ["@admin"]` +
      `nix.daemonIOLowPriority` were already covered by P1's synchronized nix-settings module;
      `computerName`/`hostName`/`localHostName` + `knownNetworkServices`; svim blacklist wired via a new
      `svim` feature (`xdg.configFile`), with `Kitty` → `Alacritty`.
- [x] Port the common-packages list, distributed across owning features: new core `documents`
      (pandoc, multimarkdown, hunspell, enchant, languagetool, fontconfig, `aspellWithDicts` en +
      en-computers + en-science + da — `de` dropped), `media` (ffmpeg, imagemagick, graphviz), and `latex`
      (texlab, texliveFull, bibutils) features; `stylelint` → javascript, `xsel` → cli-tools (NixOS + HM,
      Linux-guarded). `aspell` in the emacs feature uses the same dict set as `documents` so they never
      diverge.
- [x] Port the NixOS desktop user packages (signal-desktop, libreoffice-qt, hunspell dicts, flameshot) into
      `mbv-workstation` directly (via a small Home Manager module).

---

## Milestone 6 — Hardening, CI, polish

> Status: **in progress** — snapshot tests and leaf CI are written and green; what remains is hosting the
> leaves so their workflows actually run, and the (deferred) stub-input pattern.

- [x] `nixfmt` + statix + deadnix configured (via treefmt) and passing in all three repos.
- [~] CI (`nix flake check`) per repo — core workflow is in place; leaf workflows (`personal`, `work`) are
      now written as thin GitHub Actions wrappers that check out core and run `nix run .#ci` (all CI logic
      is Nix-contained: `nix flake check` incl. treefmt + namaka, with `CORE_PATH` overriding the core
      input). They are **pending repo hosting** to actually exercise.
- [x] Namaka snapshot tests across core + personal + work for representative modules and host configs.
      Core snapshots the `mine.*` identity framework; leaves snapshot the deterministic toplevel
      `drvPath` (`mbv-workstation`, `work`; `mbv-mba` is gated on `secrets/rekeyed/mbv-mba` being committed
      — see Milestone 7). Tests are pure evaluation, so they run byte-identically on every machine
      (no `builtins.currentSystem` leakage; the builders pin `system` explicitly).
- [~] Stub-input pattern in core so public CI never requires private inputs — deferred (all current core
      inputs are public); revisit when a private input is added.
- [x] Document `--override-input core path:../core` in each leaf README.

---

## Milestone 7 — Hardware-dependent bring-up

> Status: **not started** (requires the Mac, the physical servers, and the work laptop).

- [ ] Deploy/switch `mbv-mba` on real hardware (rekey + `darwin-rebuild switch --flake .#mbv-mba` or
      deploy-rs) and verify a core feature behaves identically on the Mac and on NixOS. **Prerequisite**:
      `secrets/rekeyed/mbv-mba/` (and `secrets/rekeyed/mbv-desktop/`) are not yet committed, so those two
      host configs don't evaluate from a clean checkout — rekey them with the YubiKey and commit the
      outputs (this also activates the gated `mbv-mba` snapshot test).
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
| `portaudio` | Dropped (unused; not worth carrying in the new fleet). |
| `aspellDicts.de` | Dropped (operator decision); keep en / en-computers / en-science / da. |
| `mbsyncrc` secret | No longer consumed — email uses declarative `accounts.email.mbsync` (secret still declared, rekeyed, but unused). |
| `extrauser.nix` (gameruser specialisation) | Dropped. |
| `overclocking.nix` | Dropped (file was empty; amdgpu overdrive + lact + gamemode are already ported). |
| `permittedInsecurePackages = ["electron-39.8.10"]` | Dropped. |
| fenix | Replaced by oxalica rust-overlay. |
| karabiner-elements custom derivation | Replaced by nix-darwin `services.karabiner-elements`. |
| Remote-builder feature | Dropped as-is (see Deferred reimplementation). |
| Inactive overlays (`spacefm`, `cargo-instruments`, `dbdcsv`) | Never wired in the old config; dropped. |
| spacefm (file manager) | Removed from nixpkgs 2026-01-24 (unmaintained upstream); the gcc14 patch is moot. Replaced by `thunar` (already in the `desktop` profile). |
| `feather-font` (Feather Icons icon font) | Installed-but-unused in the old desktop fonts preset; nerd-fonts + font-awesome + all-the-icons already cover icon fonts. |

## Deferred reimplementation

Features worth having later, but not worth porting as-is. Recorded with enough detail to rebuild them
cleanly.

- **Remote builders** (old `local.builder`): Tailscale-based remote Nix builders — a `builder` user,
  `nix.buildMachines` over the tailnet, and `enableLocalBuilder`. It never worked well and needs a redesign;
  the *purpose* (offload builds to faster fleet machines over Tailscale) is worth preserving.
- **Ephemeral installer / ISO** (old `hosts/ephemeral` + `nixos-generators`): a bootstrapping installer
  built with disko + impermanence, a `zpool` bootstrap + `nixos-install --flake` script, `persist.nix`, and
  a Tailscale auth file. Recreate a cleaner version later on top of core's disko/impermanence wiring.
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
