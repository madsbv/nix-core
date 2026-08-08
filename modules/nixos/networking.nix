{
  config,
  lib,
  ...
}:
{
  config = {
    networking = {
      hostName = lib.mkDefault config.mine.hostName;
      firewall = {
        allowPing = true;
        logRefusedConnections = lib.mkDefault false;
      };
      networkmanager.enable = true;
      useNetworkd = true;
      useDHCP = false;
      nameservers = lib.mkDefault [
        "9.9.9.9"
        "149.112.112.112"
        "2620:fe::fe"
        "2620:fe::9"
        "1.1.1.2"
        "1.0.0.2"
        "2606:4700:4700::1112"
        "2606:4700:4700::1002"
      ];
    };

    systemd = {
      network.wait-online.enable = false;
      services = {
        NetworkManager-wait-online.enable = false;
        systemd-networkd.stopIfChanged = false;
        systemd-resolved.stopIfChanged = false;
      };
    };
  };
}
