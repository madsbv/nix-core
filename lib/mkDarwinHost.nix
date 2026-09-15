# nix-darwin host builder (shared NixOS/darwin wiring only; no darwin-specific
# system modules live in core).
#
# Curried over core's pinned `inputs` and nixpkgs `lib`, then becomes a
# flake-parts module that registers `mkDarwinHost` on `config.flake.lib`
# (auto-discovered from `lib/` by the framework).
#
# The primary user's Home Manager modules are threaded to `users-darwin.nix` via
# `mine.users.<primary>.homeManagerModules`, mirroring how `mkNixosHost` feeds
# `users.nix`; the account/primaryUser/`useGlobalPkgs` wiring itself lives in
# `users-darwin.nix`.
{ inputs, lib }:
{ config, ... }:
let
  homeManagerDarwinModule = inputs.home-manager.darwinModules.home-manager;
  baseProfile = config.flake.profiles.base;
in
{
  flake.lib.mkDarwinHost =
    {
      system,
      hostname,
      profiles ? [ baseProfile ],
      modules ? [ ],
      identity ? [ ],
    }:
    let
      toClassKeyed = import ./_class-keyed.nix "darwin";

      profiles' = map toClassKeyed profiles;
      modules' = toClassKeyed modules;

      profilesDarwin = lib.concatLists (map (p: p.darwin) profiles');
      profilesHm = lib.concatLists (map (p: p.homeManager) profiles');
      modulesDarwin = modules'.darwin;
      modulesHm = modules'.homeManager;

      # The primary user's Home Manager config is threaded through
      # `mine.users.<primary>.homeManagerModules`, consumed by `users-darwin.nix`
      # (which adds the `mine` mirror and `home.stateVersion`).
      primaryUserHm =
        { config, lib, ... }:
        {
          mine.users.${config.mine.primaryUser}.homeManagerModules = lib.mkDefault (profilesHm ++ modulesHm);
        };
    in
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;
      modules = [
        {
          networking.hostName = lib.mkDefault hostname;
        }
        homeManagerDarwinModule
        primaryUserHm
      ]
      ++ profilesDarwin
      ++ modulesDarwin
      ++ identity;
    };
}
