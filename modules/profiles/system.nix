{ config, ... }:
{
  flake.modules.nixos = {
    console = ../nixos/console.nix;
    networking = ../nixos/networking.nix;
    openssh = ../nixos/openssh.nix;
    persistence = import ../nixos/persistence.nix { inputs = config.flake.inputs; };
    system-programs = ../nixos/system-programs.nix;
  };

  flake.profiles.system = {
    nixos = [
      "console"
      "networking"
      "openssh"
      "persistence"
      "system-programs"
    ];
    homeManager = [ ];
    darwin = [ ];
  };
}
