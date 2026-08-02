{ config, ... }:
{
  flake.profiles.editors = {
    nixos = [ ];
    homeManager = [
      config.flake.modules.homeManager.emacs
      config.flake.modules.homeManager.nixvim
    ];
    darwin = [ ];
  };
}
