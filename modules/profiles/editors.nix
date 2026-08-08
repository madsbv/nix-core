{ config, ... }:
{
  flake.profiles.editors = {
    nixos = [ config.flake.modules.nixos.neovim ];
    homeManager = [
      config.flake.modules.homeManager.emacs
      config.flake.modules.homeManager.nixvim
    ];
    darwin = [ ];
  };
}
