# User framework for nix-darwin: turns `mine.users` into darwin user accounts
# and per-user Home Manager configs. No extraGroups/group management (darwin
# uses `knownUsers`/`knownGroups` or admin group membership via sudo config).
#
# The per-user Home Manager configs and SSH identity secrets are shared with the
# NixOS user module (`users.nix`) via `_user-common.nix`; only the account
# definition (uid/home/knownUsers) is darwin-specific here. The primary-user +
# `useGlobalPkgs`/`useUserPackages` wiring also lives here (previously inlined in
# `lib/mkDarwinHost.nix`).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mine;

  # Darwin requires every user to have a UID. Auto-assign from 501 upward
  # when the leaf doesn't specify one.
  indexedUsers = lib.imap0 (i: name: {
    inherit name;
    user = cfg.users.${name};
    index = i;
  }) (builtins.attrNames cfg.users);
in
{
  imports = [ ./_user-common.nix ];

  # `mkDarwinHost` always imports the home-manager darwin module, so these are
  # set on every darwin host; the guard mirrors the `config ? home-manager`
  # pattern in `_user-common.nix`.
  home-manager = lib.mkIf (config ? home-manager) {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  system.primaryUser = config.mine.primaryUser;

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
}
