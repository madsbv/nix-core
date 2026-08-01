{ config, ... }:
{
  flake.profiles.base = {
    nixos = [ config.flake.modules.nixos.base ];
    homeManager = [ config.flake.modules.homeManager.base ];
    darwin = [ config.flake.modules.darwin.base ];
  };
}
