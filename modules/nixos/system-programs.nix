{
  config,
  lib,
  ...
}:
{
  config = {
    programs = {
      git = {
        enable = true;
        lfs = {
          enable = true;
          enablePureSSHTransfer = true;
        };
      };
      command-not-found.enable = false;
    };

    users.mutableUsers = lib.mkDefault false;

    security.sudo = {
      execWheelOnly = true;
      extraConfig = ''
        Defaults lecture = never
      '';
    };

    services.zfs = lib.mkIf config.boot.zfs.enabled {
      autoSnapshot.enable = true;
      autoSnapshot.monthly = 3;
      autoScrub.enable = true;
    };
  };
}
