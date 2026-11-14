_: {
  flake.modules.nixos.systemd-boot = _: {
    boot = {
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
