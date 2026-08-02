{
  inputs,
  lib,
  homeManagerModule,
  homeManagerBase,
  baseProfile,
}:
{
  system,
  hostname,
  profiles ? [ baseProfile ],
  modules ? [ ],
  identity ? [ ],
  # Home Manager modules per *additional* user, keyed by username. The primary
  # user gets the `profiles`/`modules` HM lists automatically; this lets leaves
  # attach HM config (referencing core's `config.flake.modules.*`) to other
  # users too.
  users ? { },
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
in
inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    {
      networking.hostName = lib.mkDefault hostname;
    }
    homeManagerModule
    # User creation and per-user Home Manager wiring live in
    # `modules/system/users.nix` (part of the base profile). The builder only
    # feeds the leaf-facing `profiles`/`modules` HM lists to the users
    # framework for the primary user, and threads `users` for the rest.
    (
      {
        config,
        ...
      }:
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
        };

        # The base composite (identity options, agenix, base16) is included in
        # every user's Home Manager evaluation: for the primary via
        # `profilesHm` (the base profile), for additional users by prepending
        # `homeManagerBase` below.
        mine.users = lib.mkMerge [
          (lib.mapAttrs (_name: hm: {
            homeManagerModules = lib.mkDefault ([ homeManagerBase ] ++ hm);
          }) (lib.filterAttrs (name: _: name != config.mine.primaryUser) users))
          {
            ${config.mine.primaryUser}.homeManagerModules = lib.mkDefault (profilesHm ++ modulesHm);
          }
        ];
      }
    )
  ]
  ++ profilesNixos
  ++ modulesNixos
  ++ identity;
}
