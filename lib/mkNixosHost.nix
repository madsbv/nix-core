{
  inputs,
  lib,
  homeManagerModule,
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
        nixos = value;
        homeManager = [ ];
        darwin = [ ];
      }
    else if value ? nixos then
      value
    else
      {
        nixos = [ value ];
        homeManager = [ ];
        darwin = [ ];
      };

  profiles' = map toClassKeyed profiles;
  modules' = toClassKeyed modules;

  profilesNixos = lib.concatLists (map (p: p.nixos) profiles');
  profilesHm = lib.concatLists (map (p: p.homeManager) profiles');
  modulesNixos = modules'.nixos;
  modulesHm = modules'.homeManager;

  userWiring =
    { config, lib, ... }:
    let
      user = config.mine.user.username;
    in
    {
      users.users.${user} = {
        isNormalUser = true;
        extraGroups = lib.mkDefault [ "wheel" ];
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${user}.imports = [
          # Home Manager evaluates in its own module system: the `mine.*`
          # values set here in the system evaluation are not visible inside it.
          # Mirror the resolved subtree so value-driven feature modules (AD-4)
          # read the same identity in integrated mode.
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
inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    {
      networking.hostName = lib.mkDefault hostname;
    }
    homeManagerModule
    userWiring
  ]
  ++ profilesNixos
  ++ modulesNixos
  ++ identity;
}
