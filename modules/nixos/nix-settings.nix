{ lib, ... }:
{
  config = {
    nix = {
      daemonCPUSchedPolicy = "idle";
      daemonIOSchedClass = "idle";
    };

    systemd.services.nix-daemon.serviceConfig.OOMScoreAdjust = lib.mkDefault 250;
  };
}
