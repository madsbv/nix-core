{ config, ... }:
{
  flake.profiles.dev-base = {
    nixos = [ ];
    homeManager = [
      config.flake.modules.homeManager.git
      config.flake.modules.homeManager.ssh
      config.flake.modules.homeManager.gh
      config.flake.modules.homeManager.direnv
      config.flake.modules.homeManager.dev-tools
    ];
    darwin = [ ];
  };
}
