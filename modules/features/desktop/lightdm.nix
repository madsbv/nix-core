_: {
  flake.modules.nixos.lightdm =
    { lib, ... }:
    {
      services.xserver = {
        enable = true;
        autoRepeatDelay = lib.mkDefault 200;
        autoRepeatInterval = lib.mkDefault 40;
        xkb = {
          layout = lib.mkDefault "us";
          variant = lib.mkDefault "altgr-intl";
        };
        displayManager.lightdm.enable = true;
      };
    };
}
