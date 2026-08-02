{
  inputs,
  lib,
  homeManagerDarwinModule,
  baseProfile,
}:
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
          # Home Manager evaluation (see lib/mkNixosHost.nix).
          {
            inherit (config) mine;
          }
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
}
