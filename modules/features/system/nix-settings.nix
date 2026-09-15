# Synchronized Nix settings (ported from the old `presets/system/common/nix.nix`,
# `presets/nixos/common/nix.nix` and `presets/darwin/common/default.nix`).
#
# One feature file contributes to all three module classes. `mine.nix.settings`
# (declared in `options.nix`) is the synchronized subset; each class adds its own
# platform-specific settings on top. `mine.nix.settings` is mirrored into Home
# Manager evaluations via `modules/_hm-mirror.nix`, so `nix.settings` stays in
# sync between the system and the user nix.conf.
_:
let
  # Settings shared by every system type. `sandbox`, `trusted-users` and the
  # extra `experimental-features` are platform-specific and set per class below.
  commonSettings = {
    download-buffer-size = 268435456; # 256 MiB
    keep-going = true;
    show-trace = true;
    warn-dirty = false;
    max-free = 10 * 1024 * 1024 * 1024; # 10 GiB
    min-free = 1 * 1024 * 1024 * 1024; # 1 GiB
    builders-use-substitutes = true;
    fallback = true;
    connect-timeout = 3;
    log-lines = 50;
    substituters = [
      "https://nix-community.cachix.org/"
      "https://cache.garnix.io"
      "https://numtide.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
    ];
    experimental-features = [
      "nix-command"
      "flakes"
      "ca-derivations"
      "fetch-closure"
      "recursive-nix"
      "blake3-hashes"
    ];
  };
in
{
  flake.modules.nixos.nix-settings =
    {
      config,
      lib,
      ...
    }:
    {
      mine.nix.settings = lib.mkDefault commonSettings;

      nix.settings = lib.mkMerge [
        config.mine.nix.settings
        {
          sandbox = true;
          trusted-users = [
            "root"
            "@admin"
            "@wheel"
            "@builders"
          ];
          experimental-features = [
            "auto-allocate-uids"
            "cgroups"
          ];
          auto-allocate-uids = lib.mkDefault true;
          system-features = [ "uid-range" ];
        }
      ];

      # When `mine.nix.clean.enable` (nh clean) is on, nh owns periodic GC and
      # the NixOS nix-collect-garbage timer is disabled to avoid double work
      # (the nh NixOS module warns about exactly this combination).
      nix.gc = {
        automatic = lib.mkDefault (config.mine.nix.gc.enable && !config.mine.nix.clean.enable);
        dates = "weekly";
        options = config.mine.nix.gc.options;
      };

      nix.optimise.automatic = lib.mkDefault (!config.boot.isContainer);

      nix.daemonCPUSchedPolicy = "idle";
      nix.daemonIOSchedClass = "idle";

      systemd.services.nix-daemon.serviceConfig.OOMScoreAdjust = lib.mkDefault 250;

      nixpkgs.config.allowUnfree = lib.mkDefault config.mine.nix.allowUnfree;
    };

  flake.modules.darwin.nix-settings =
    {
      config,
      lib,
      ...
    }:
    {
      mine.nix.settings = lib.mkDefault commonSettings;

      nix.settings = lib.mkMerge [
        config.mine.nix.settings
        {
          # sandbox = true / relaxed has problems on Darwin (see
          # https://github.com/NixOS/nix/issues/4119).
          sandbox = false;
          trusted-users = [ "@admin" ];
        }
      ];

      nix.gc = {
        automatic = lib.mkDefault (config.mine.nix.gc.enable && !config.mine.nix.clean.enable);
        interval = {
          Weekday = 0;
          Hour = 2;
          Minute = 0;
        };
        options = config.mine.nix.gc.options;
      };

      nix.optimise.automatic = lib.mkDefault config.mine.nix.optimise.automatic;

      nix.daemonIOLowPriority = lib.mkDefault true;

      nixpkgs.config.allowUnfree = lib.mkDefault config.mine.nix.allowUnfree;
    };

  flake.modules.homeManager.nix-settings =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      mine.nix.settings = lib.mkDefault commonSettings;

      nix.settings = config.mine.nix.settings;

      # Home Manager needs a `nix.package` to generate `~/.config/nix/nix.conf`
      # from `nix.settings`; integrated hosts forward the OS package (overriding
      # this default), standalone Home Manager needs it set here.
      nix.package = lib.mkDefault pkgs.nix;

      # On integrated hosts (`submoduleSupport.enable`, i.e. useGlobalPkgs)
      # `nixpkgs.*` is disabled in the Home Manager evaluation and the OS-level
      # nix-settings module sets allowUnfree on the shared nixpkgs instead.
      # Standalone Home Manager has its own nixpkgs, so set it here. The mkIf
      # must wrap the whole `nixpkgs.config` (not the nested key) so the
      # condition is applied at the option level.
      nixpkgs.config = lib.mkIf (!config.submoduleSupport.enable) {
        allowUnfree = lib.mkDefault config.mine.nix.allowUnfree;
      };
    };
}
