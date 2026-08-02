{ config, ... }:
{
  flake.profiles.dev = {
    nixos = [
      config.flake.modules.nixos.docker
    ];
    homeManager = [
      config.flake.modules.homeManager.git
      config.flake.modules.homeManager.ssh
      config.flake.modules.homeManager.gh
      config.flake.modules.homeManager.direnv
      config.flake.modules.homeManager.python
      config.flake.modules.homeManager.shell-dev
      config.flake.modules.homeManager.go
      config.flake.modules.homeManager.rust
      config.flake.modules.homeManager.javascript
      config.flake.modules.homeManager.java
      config.flake.modules.homeManager.lua
      config.flake.modules.homeManager.nix-dev
      config.flake.modules.homeManager.fortran
      config.flake.modules.homeManager.R
      config.flake.modules.homeManager.dev-tools
      config.flake.modules.homeManager.docker
    ];
    darwin = [
      config.flake.modules.darwin.docker
    ];
  };
}
