# nix-core framework.
#
# This is a self-contained flake-parts module. Core exports it as
# `flakeModules.default`; leaf flakes import it to get the `flake.modules`
# registry, `flake.profiles` aggregates, the `flake.lib` builders, and core's
# pinned inputs (via `config.flake.inputs`), pulling core's feature/profile
# trees into their own evaluation.
#
# It closes over core's pinned `inputs`, so leaves reach home-manager,
# nix-darwin, agenix(-rekey) and deploy-rs through core without declaring them.
{ inputs }:
{ lib, ... }:
let
  load = import ../lib/load.nix { };
  loadWithSkip = skip: import ../lib/load.nix { inherit skip; };
  features = load { dir = ./features; };
  profiles = load { dir = ./profiles; };

  # Builders are flake-parts modules too: every `.nix` file under `lib/` is
  # curried over core's pinned inputs and imported as a flake-parts module,
  # where it registers itself on `config.flake.lib`. `load.nix` is the loader
  # itself, not a builder, so it is excluded.
  builderFiles = loadWithSkip (name: name == "load.nix" || builtins.substring 0 1 name == "_") {
    dir = ../lib;
  };
  builders = map (file: import file { inherit inputs lib; }) builderFiles;
in
{
  imports = [
    inputs.flake-parts.flakeModules.modules
    inputs.agenix-rekey.flakeModules.default
    inputs.home-manager.flakeModules.default
    inputs.nix-darwin.flakeModules.default
    # `agenix.nix`/`base.nix`/`color-scheme.nix` are applied with core's inputs
    # here rather than imported as paths: their inner modules read
    # `inputs.agenix`/`inputs.agenix-rekey`/`inputs.impermanence`/`inputs.base16`,
    # which must resolve to core's pinned inputs. When this flake module is
    # consumed by a leaf, the module-system `inputs` argument is the *leaf's*
    # inputs, so relying on it would break. Currying keeps the closure over
    # core's inputs.
    (import ./agenix.nix { inherit inputs; })
    (import ./base.nix { inherit inputs; })
    (import ./color-scheme.nix { inherit inputs; })
    (import ./features/editors/_nixvim.nix { inherit inputs; })
    (import ./darwin/homebrew.nix { inherit inputs; })
    (import ./features/dev/_direnv.nix { inherit inputs; })
    (import ./features/dev/_rust.nix { inherit inputs; })
    # devShell uses `config.flake.inputs` (core's re-exported inputs) instead of
    # currying — it needs to work identically in core and in leaves.
    ./devShell.nix
    # treefmt-nix propagates to leaf flakes so `nix fmt` and the treefmt check
    # work identically in all three repos. The flakeModule is imported from
    # core's pinned treefmt-nix input.
    inputs.treefmt-nix.flakeModule
    {
      perSystem.treefmt = {
        projectRootFile = "flake.nix";
        programs = {
          nixfmt.enable = true;
          deadnix.enable = true;
          statix.enable = true;
        };
      };
    }
    # Override the treefmt-nix formatter to disable the eval cache.
    # Without this, `nix fmt` uses ~/.cache/treefmt and can silently skip files
    # that the sandboxed `nix flake check` (which runs `treefmt --no-cache`)
    # correctly detects as unformatted.
    {
      perSystem =
        {
          config,
          pkgs,
          lib,
          ...
        }:
        {
          formatter = lib.mkForce (
            pkgs.writeShellScriptBin "treefmt" ''
              export TREEFMT_NO_CACHE=1
              exec ${config.treefmt.build.wrapper}/bin/treefmt "$@"
            ''
          );
        };
    }
  ]
  ++ features
  ++ profiles
  ++ builders;

  options.flake = {
    profiles = lib.mkOption {
      type = lib.types.lazyAttrsOf (
        lib.types.submodule {
          options = {
            nixos = lib.mkOption {
              type = lib.types.listOf lib.types.raw;
              default = [ ];
            };
            homeManager = lib.mkOption {
              type = lib.types.listOf lib.types.raw;
              default = [ ];
            };
            darwin = lib.mkOption {
              type = lib.types.listOf lib.types.raw;
              default = [ ];
            };
          };
        }
      );
      default = { };
      description = "Class-keyed module aggregates, composed by the builders.";
    };

    lib = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
      description = "nix-core builder functions (auto-discovered from lib/).";
    };

    deploy = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
      description = "deploy-rs deployment nodes.";
    };

    doomdirs = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
      description = "Store-built Doom Emacs DOOMDIRs, keyed by host (via config.flake.lib.mkDoomdir).";
    };

    flakeModules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = { };
      description = "Reusable flake-parts modules exported by this flake.";
    };

    # Core's pinned inputs, re-exported so leaves can reach transitive inputs
    # (e.g. `config.flake.inputs.disko.nixosModules.disko`) without declaring
    # them as their own flake inputs.
    inputs = lib.mkOption {
      type = lib.types.raw;
      description = "core's pinned flake inputs.";
    };
  };

  config.flake.inputs = inputs;
}
