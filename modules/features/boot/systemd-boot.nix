_: {
  flake.modules.nixos.systemd-boot = { lib, ... }: {
    boot = {
      initrd.systemd.enable = lib.mkDefault true;
      tmp.cleanOnBoot = true;
      zfs.forceImportRoot = false;
      loader = {
        systemd-boot = {
          enable = true;
          memtest86.enable = true;
        };
        efi.canTouchEfiVariables = true;
      };
    };
  };
}
