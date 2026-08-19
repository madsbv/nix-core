# User framework for nix-darwin: turns `mine.users` into darwin user accounts
# and per-user Home Manager configs. No extraGroups/group management (darwin
# uses `knownUsers`/`knownGroups` or admin group membership via sudo config).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mine;

  hmUsers = lib.filterAttrs (_: u: !u.isSystemUser && u.homeManagerModules != [ ]) cfg.users;

  ageSecretsDir = cfg.agenix.secretsDir;
  hostKeyName = cfg.hostName;

  # Darwin requires every user to have a UID. Auto-assign from 501 upward
  # when the leaf doesn't specify one.
  indexedUsers = lib.imap0 (i: name: {
    inherit name;
    user = cfg.users.${name};
    index = i;
  }) (builtins.attrNames cfg.users);
in
{
  users.users = builtins.listToAttrs (
    map (
      {
        name,
        user,
        index,
      }:
      lib.nameValuePair name {
        home = "/Users/${user.username}";
        shell = if user.shell != null then user.shell else pkgs.zsh;
        uid = if user.uid != null then user.uid else 501 + index;
        description = user.fullName;
      }
    ) indexedUsers
  );

  users.knownUsers = builtins.attrNames cfg.users;

  home-manager.users = lib.mkIf (config ? home-manager) (
    lib.mapAttrs (_name: u: {
      imports = [
        (import ../_hm-mirror.nix { osMine = config.mine; })
        {
          home.stateVersion = lib.mkDefault config.mine.system.stateVersionFinal;
        }
      ]
      ++ u.homeManagerModules;
    }) hmUsers
  );

  age.secrets = lib.mkIf (ageSecretsDir != null) (
    lib.mapAttrs' (
      _: u:
      lib.nameValuePair "id.${hostKeyName}.${u.username}" {
        rekeyFile = "${ageSecretsDir}/ssh/id_ed25519.${hostKeyName}.${u.username}.age";
        owner = u.username;
      }
    ) cfg.users
  );
}
