# Shell profile: class-keyed aggregate of the shell feature.
{ config, ... }:
{
  flake.profiles.shell = {
    nixos = [ config.flake.modules.nixos.shell ];
    homeManager = [ config.flake.modules.homeManager.shell ];
    darwin = [ ];
  };
}
