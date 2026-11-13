{ config, ... }:
{
  flake.profiles.dev = {
    nixos = [
      config.flake.modules.nixos.docker
      config.flake.modules.nixos.rust
      config.flake.modules.nixos.nix-dev
      config.flake.modules.nixos.tracing
    ];
    homeManager = config.flake.profiles.dev-base.homeManager ++ [
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
      config.flake.modules.homeManager.latex
      config.flake.modules.homeManager.c-cpp
      config.flake.modules.homeManager.kcl
      config.flake.modules.homeManager.protobuf
      config.flake.modules.homeManager.docker
      config.flake.modules.homeManager.kubernetes
      config.flake.modules.homeManager.k9s
      config.flake.modules.homeManager.opencode
    ];
    darwin = [
      config.flake.modules.darwin.docker
      config.flake.modules.darwin.rust
    ];
  };
}
