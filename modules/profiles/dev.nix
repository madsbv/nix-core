# Dev profile: class-keyed aggregate of the shared development-tooling
# features. Grows as more `features/dev/*` modules land (gh, direnv,
# toolchains, docker, …).
{ config, ... }:
{
  flake.profiles.dev = {
    nixos = [ ];
    homeManager = [
      config.flake.modules.homeManager.git
      config.flake.modules.homeManager.ssh
    ];
    darwin = [ ];
  };
}
