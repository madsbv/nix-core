{ config, ... }:
{
  flake.profiles.desktop = {
    nixos = [
      config.flake.modules.nixos.pipewire
      config.flake.modules.nixos.lightdm
      config.flake.modules.nixos.fonts
      config.flake.modules.nixos.xdg-desktop
      config.flake.modules.nixos.bluetooth-desktop
      config.flake.modules.nixos.printing
      config.flake.modules.nixos.awesomewm
    ];
    homeManager = [
      config.flake.modules.homeManager.awesomewm
    ];
    darwin = [ ];
  };
}
