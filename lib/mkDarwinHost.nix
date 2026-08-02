# nix-darwin host builder (shared NixOS/darwin wiring only; no darwin-specific
# system modules live in core).
#
# Curried over core's pinned `inputs` and nixpkgs `lib`, then becomes a
# flake-parts module that registers `mkDarwinHost` on `config.flake.lib`
# (auto-discovered from `lib/` by the framework).
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
      toClassKeyed =
        value:
        if builtins.isList value then
          {
            darwin = value;
            homeManager = [ ];
          }
        else if value ? darwin then
          value
        else
          {
            darwin = [ value ];
            homeManager = [ ];
          };

      profiles' = map toClassKeyed profiles;
      modules' = toClassKeyed modules;

      profilesDarwin = lib.concatLists (map (p: p.darwin) profiles');
      profilesHm = lib.concatLists (map (p: p.homeManager) profiles');
      modulesDarwin = modules'.darwin;
      modulesHm = modules'.homeManager;

      userWiring =
        { config, lib, ... }:
        let
          user = config.mine.user.username;
        in
        {
          home-manager = {
            users.${user}.imports = [
              # Mirror the system evaluation's `mine.*` values into the nested
              # Home Manager evaluation, pruning to the options that evaluation
              # actually declares (see modules/_hm-mirror.nix).
              (import ../modules/_hm-mirror.nix { osMine = config.mine; })
              {
                home.stateVersion = lib.mkDefault config.mine.system.stateVersionFinal;
              }
            ]
            ++ profilesHm
            ++ modulesHm;
          };
        };
    in
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;
      modules = [
        {
          networking.hostName = lib.mkDefault hostname;
        }
        (
          {
            config,
            lib,
            ...
          }:
          {
            # Resolved from `mine.system.stateVersion`; leaves may override
            # `system.stateVersion` directly.
            system.stateVersion = lib.mkDefault config.mine.system.stateVersionFinal;
          }
        )
        homeManagerDarwinModule
        userWiring
      ]
      ++ profilesDarwin
      ++ modulesDarwin
      ++ identity;
    };
}
