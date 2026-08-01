# nix-core framework.
#
# This is a self-contained flake-parts module. Core exports it as
# `flakeModules.default`; leaf flakes import it to get the `flake.modules`
# registry, `flake.profiles` aggregates, the `flake.lib` builders, and core's
# feature/profile trees pulled into their own evaluation.
#
# It closes over core's pinned `inputs`, so leaves reach home-manager,
# nix-darwin, agenix(-rekey) and deploy-rs through core without declaring them.
{ inputs }:
{ config, lib, ... }:
let
  load = import ../lib/load.nix { };
  features = load { dir = ./features; };
  profiles = load { dir = ./profiles; };

  mkNixosHost = import ../lib/mkNixosHost.nix {
    inherit inputs lib;
    baseProfile = config.flake.profiles.base;
    homeManagerModule = inputs.home-manager.nixosModules.home-manager;
  };

  mkHomeConfig = import ../lib/mkHomeConfig.nix {
    inherit inputs lib;
    baseProfile = config.flake.profiles.base;
  };

  mkDarwinHost = import ../lib/mkDarwinHost.nix {
    inherit inputs lib;
    baseProfile = config.flake.profiles.base;
    homeManagerDarwinModule = inputs.home-manager.darwinModules.home-manager;
  };

  mkDeploy = import ../lib/mkDeploy.nix { inherit inputs lib; };

  builders = {
    inherit
      mkNixosHost
      mkHomeConfig
      mkDarwinHost
      mkDeploy
      load
      ;
  };
in
{
  imports = [
    inputs.flake-parts.flakeModules.modules
    inputs.home-manager.flakeModules.default
    inputs.nix-darwin.flakeModules.default
    # `agenix.nix` is applied with core's inputs here rather than imported as a
    # path: its inner module reads `inputs.agenix`/`inputs.agenix-rekey`, which
    # must resolve to core's pinned inputs. When this flake module is consumed
    # by a leaf, the module-system `inputs` argument is the *leaf's* inputs, so
    # relying on it would break. Currying keeps the closure over core's inputs.
    (import ./agenix.nix { inherit inputs; })
    ./base.nix
  ]
  ++ features
  ++ profiles;

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
      type = lib.types.raw;
      description = "nix-core builder functions.";
    };

    deploy = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
      description = "deploy-rs deployment nodes.";
    };

    flakeModules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = { };
      description = "Reusable flake-parts modules exported by this flake.";
    };
  };

  config.flake.lib = builders;
}
