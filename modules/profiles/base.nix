{ config, ... }:
{
  flake.profiles.base = {
    nixos = [
      config.flake.modules.nixos.base
      config.flake.modules.nixos.cli-tools
    ];
    homeManager = [
      config.flake.modules.homeManager.base
      config.flake.modules.homeManager.cli-tools
      config.flake.modules.homeManager.media
      config.flake.modules.homeManager.documents
    ];
    darwin = [
      config.flake.modules.darwin.base
      config.flake.modules.darwin.cli-tools
    ];
  };
}
