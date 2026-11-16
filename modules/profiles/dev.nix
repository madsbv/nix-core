{ config, ... }:
{
  flake.profiles.dev = {
    nixos = [
      "docker"
      "rust"
      "nix-dev"
      "tracing"
    ];
    homeManager = config.flake.profiles.dev-base.homeManager ++ [
      "python"
      "shell-dev"
      "go"
      "rust"
      "javascript"
      "java"
      "lua"
      "nix-dev"
      "fortran"
      "R"
      "latex"
      "c-cpp"
      "kcl"
      "protobuf"
      "docker"
      "kubernetes"
      "k9s"
      "opencode"
    ];
    darwin = [
      "docker"
      "rust"
    ];
  };
}
