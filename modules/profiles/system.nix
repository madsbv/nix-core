{ config, ... }:
{
  flake.profiles.system = {
    nixos = [
      ../nixos/console.nix
      ../nixos/networking.nix
      ../nixos/openssh.nix
      (import ../nixos/persistence.nix { inputs = config.flake.inputs; })
      ../nixos/system-programs.nix
    ];
    homeManager = [ ];
    darwin = [ ];
  };
}
