# Remote-building support: a locked-down `builder` user that other machines
# SSH into (via Tailscale, controlled by ACLs), and the `nix.buildMachines`
# list for using other fleet nodes as remote builders. Option declarations
# live in `modules/options.nix`; this module only wires the behavior. All
# node/host specifics are leaf-supplied via `mine.remoteBuilder`.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mine.remoteBuilder;
in
{
  config = lib.mkMerge [
    (lib.mkIf cfg.enableLocalBuilder {
      users.users.builder = {
        isSystemUser = true;
        group = "builders";
        openssh.authorizedKeys.keys = cfg.authorizedKeys;
      }
      # Darwin-specific shape for the linux-builder VM user. NOTE: this branch
      # is currently unreachable — this module is only imported by `nixos.base`,
      # so it only ever evaluates in a NixOS eval (isDarwin = false). Wiring it
      # into a darwin base is deferred until the darwin hosts land (M4), where
      # it can be exercised; see PLAN.md.
      // lib.mkIf pkgs.stdenv.isDarwin {
        isHidden = false;
        uid = 42;
        gid = 42;
        home = "/var/nix-builder";
      };
      users.groups.builders = lib.mkIf pkgs.stdenv.isLinux { };
    })
    (lib.mkIf cfg.enableRemoteBuilders {
      nix.buildMachines = cfg.buildMachines;
      # Avoid long stalls when remote builders are unreachable.
      programs.ssh.extraConfig = ''
        ConnectTimeout = 10
        ServerAliveInterval = 5
        ServerAliveCountMax = 2
      '';
    })
  ];
}
