{ config, ... }:
{
  flake.profiles.terminal = {
    nixos = [ ];
    homeManager = [ config.flake.modules.homeManager.terminal ];
    darwin = [ config.flake.modules.darwin.terminal ];
  };
}
