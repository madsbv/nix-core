{ lib, ... }:
{
  config = {
    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      font = lib.mkDefault "Lat2-Terminus16";
      keyMap = lib.mkDefault "us";
    };
    hardware.enableRedistributableFirmware = true;
  };
}
