{
  inputs,
  lib,
  optionsModule,
  agenixDarwinModule,
  agenixHomeManagerModule,
  homeManagerDarwinModule,
}:
{
  system,
  hostname,
  profiles ? [ ],
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
        sharedModules = [
          optionsModule
          agenixHomeManagerModule
        ];
        users.${user}.imports = [
          # Mirror the system evaluation's `mine.*` values into the nested
          # Home Manager evaluation (see lib/mkNixosHost.nix).
          {
            inherit (config) mine;
          }
          {
            home.stateVersion = lib.mkDefault "25.05";
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
    optionsModule
    homeManagerDarwinModule
    agenixDarwinModule
    userWiring
  ]
  ++ profilesDarwin
  ++ modulesDarwin
  ++ identity;
}
