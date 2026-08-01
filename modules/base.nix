{ config, ... }:
{
  flake.modules = {
    nixos.base = {
      imports = [
        ./options.nix
        config.flake.modules.nixos.agenix
      ];
    };

    homeManager.base = {
      imports = [
        ./options.nix
        config.flake.modules.homeManager.agenix
      ];
    };

    darwin.base = {
      imports = [
        ./options.nix
        config.flake.modules.darwin.agenix
      ];
    };
  };
}
