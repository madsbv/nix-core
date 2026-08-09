# Remote-building support: a locked-down `builder` user that other machines
# SSH into (via Tailscale, controlled by ACLs), and the `nix.buildMachines`
# list for using other fleet nodes as remote builders. Option declarations
# live in `modules/options.nix`; this module only wires the behavior. All
# node/host specifics are leaf-supplied via `mine.remoteBuilder`.
#
# Platform-specific builder-user properties are split into separate modules
# (builder-darwin.nix for the darwin linux-builder VM user, the NixOS group is
# inlined in modules/base.nix) so the module system — not inline `isDarwin`
# checks — routes behavior to the right platform.
{
  config,
  ...
}:
let
  cfg = config.mine.remoteBuilder;
in
{
  config = {
    users.users.builder = {
      isSystemUser = true;
      group = "builders";
      openssh.authorizedKeys.keys = cfg.authorizedKeys;
    };
    nix.buildMachines = cfg.buildMachines;
    programs.ssh.extraConfig = ''
      ConnectTimeout = 10
      ServerAliveInterval = 5
      ServerAliveCountMax = 2
    '';
  };
}
