# Periodic garbage collection and build UX via `nh` (nix-community/nh).
#
# One feature file contributes to all three classes:
#   - NixOS: `programs.nh` from nixpkgs (system service running `nh clean all`).
#   - nix-darwin: no `programs.nh` module exists upstream (see
#     nix-darwin/nix-darwin#1744, still unmerged), so only cleaning is wired
#     here: a launchd daemon modeled after that PR (`nh clean all`, low
#     background IO priority, calendar interval).
#   - Home Manager: `programs.nh` from Home Manager. The periodic clean runs
#     `nh clean user` on standalone Home Manager hosts; on integrated hosts
#     (inside nixos/darwin evaluations) the system-level service already GCs
#     all users' profiles, so the user service is disabled.
#
# When `mine.nix.clean.enable` is true it replaces the classic `nix.gc` timers
# (gated in `modules/features/system/nix-settings.nix`).
_: {
  flake.modules.nixos.nh =
    { config, lib, ... }:
    {
      programs.nh = {
        enable = lib.mkDefault true;
        flake = lib.mkIf (config.mine.system.registerFlake.flake != null) (
          toString config.mine.system.registerFlake.flake
        );
        clean = {
          enable = lib.mkDefault config.mine.nix.clean.enable;
          dates = lib.mkDefault config.mine.nix.clean.dates;
          extraArgs = lib.mkDefault config.mine.nix.clean.extraArgs;
        };
      };
    };

  flake.modules.homeManager.nh =
    { config, lib, ... }:
    {
      programs.nh = {
        enable = lib.mkDefault true;
        flake = lib.mkIf (config.mine.system.registerFlake.flake != null) (
          toString config.mine.system.registerFlake.flake
        );
        # `nh clean user` only makes sense for the user's own profile; on
        # integrated hosts the NixOS/nix-darwin service handles everything.
        clean = lib.mkIf (!config.submoduleSupport.enable) {
          enable = lib.mkDefault config.mine.nix.clean.enable;
          dates = lib.mkDefault config.mine.nix.clean.dates;
          extraArgs = lib.mkDefault config.mine.nix.clean.extraArgs;
        };
      };
    };

  flake.modules.darwin.nh =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      enabled = config.mine.nix.clean.enable;
    in
    {
      environment = lib.mkIf enabled {
        systemPackages = [ pkgs.nh ];
        variables = lib.mkIf (config.mine.system.registerFlake.flake != null) {
          NH_FLAKE = toString config.mine.system.registerFlake.flake;
        };
      };

      launchd.daemons.nh-clean = lib.mkIf enabled {
        path = [ config.nix.package ];
        command = "exec nh clean all ${config.mine.nix.clean.extraArgs}";
        serviceConfig = {
          RunAtLoad = false;
          StartCalendarInterval = config.mine.nix.clean.startCalendarInterval;
          WorkingDirectory = "/var/root";
          LowPriorityIO = true;
          ProcessType = "Background";
        };
      };
    };
}
