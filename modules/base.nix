# Base composites: the per-class `flake.modules.<class>.base` modules that
# every host gets by default (via the builders' `baseProfile`). Each class's
# base pulls in the identity options, agenix wiring, the system modules, and
# the NixOS-only base content. Feature modules add their own contributions to
# these composites (e.g. color-scheme).
#
# Curried over core's pinned `inputs` (same pattern as `modules/agenix.nix`):
# `modules/nixos/base.nix` references `config.mine.*` which is declared in
# `options.nix`; the minimal `nixos/base.nix` no longer imports impermanence —
# that now lives in `profiles/system.nix`.
{ inputs }:
{
  config,
  ...
}:
{
  flake.modules = {
    nixos.base = {
      imports = [
        ./options.nix
        config.flake.modules.nixos.agenix
        config.flake.modules.nixos.nix-settings
        config.flake.modules.nixos.hosts
        ./system/users.nix
        ./system/keys.nix
        ./system/builder.nix
        ./system/update-diff.nix
        ./system/register-flake.nix
        ./system/detect-hostname-change.nix
        (import ./nixos/base.nix { inherit inputs; })
        # NixOS needs a dedicated `builders` group for the remote-builder user;
        # darwin manages the linux-builder VM user differently (builder-darwin.nix).
        (_: {
          users.groups.builders = { };
        })
      ];
    };

    homeManager.base = {
      imports = [
        ./options.nix
        config.flake.modules.homeManager.agenix
        config.flake.modules.homeManager.nix-settings
        config.flake.modules.homeManager.nox
        # Prefer XDG dirs on every host type (Home Manager still defaults this
        # to `false`; leaves may override).
        ({ lib, ... }: {
          home.preferXdgDirectories = lib.mkDefault true;
        })
      ];
    };

    darwin.base = {
      imports = [
        ./options.nix
        config.flake.modules.darwin.agenix
        config.flake.modules.darwin.nix-settings
        config.flake.modules.darwin.hosts
        config.flake.modules.darwin.homebrew
        ./system/users-darwin.nix
        ./system/builder-darwin.nix
        ./system/update-diff.nix
        ./system/register-flake.nix
        (
          { config, lib, ... }:
          {
            config = lib.mkIf (config.mine.network.dns.servers != [ ]) {
              networking.dns = config.mine.network.dns.servers;
            };
          }
        )
      ];
    };
  };
}
