# Shell profile: class-keyed aggregate of the shell feature.
{ config, ... }:
{
  flake.profiles.shell = {
    nixos = [ ];
    homeManager = [ config.flake.modules.homeManager.shell ];
    darwin = [ ];
  };
}
