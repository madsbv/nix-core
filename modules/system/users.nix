# User framework for NixOS: turns the `mine.users` option into NixOS users,
# per-user Home Manager configs, and (when agenix is enabled) per-user SSH
# identity secrets. Replaces the old `systemModules/users` + `nixosModules/users`
# wiring: identity lives in `mine.*` (leaf-provided), no `flake-root` /
# `specialArgs` plumbing, no personal values in core.
#
# The primary user's Home Manager modules are threaded in by the builders
# (`mkNixosHost` feeds `profiles`/`modules` into `mine.users.<primary>`);
# every other user gets theirs from `mine.users.<name>.homeManagerModules`
# (leaf-provided, possibly via the builders' `users` parameter).
#
# The per-user Home Manager configs and SSH identity secrets are shared with the
# darwin user module (`users-darwin.nix`) via `_user-common.nix`; only the
# account definition (groups/extraGroups) is NixOS-specific here.
{ config, lib, ... }:
let
  cfg = config.mine;

  # Human users get `wheel` (for sudo) on top of their declared groups.
  humanGroups = u: u.extraGroups ++ lib.optionals (!u.isSystemUser) [ "wheel" ];
in
{
  imports = [ ./_user-common.nix ];

  users.users = lib.mapAttrs (name: u: {
    inherit (u) isSystemUser;
    isNormalUser = !u.isSystemUser;
    group = lib.mkIf u.isSystemUser name;
    extraGroups = humanGroups u;
    shell = lib.mkIf (u.shell != null) u.shell;
    uid = lib.mkIf (u.uid != null) u.uid;
    initialHashedPassword = lib.mkIf (u.initialHashedPassword != null) u.initialHashedPassword;
    openssh.authorizedKeys.keys = u.sshAuthorizedKeys;
  }) cfg.users;

  # System users (robots/service accounts) each get a matching group; NixOS
  # no longer defaults ungrouped users to nogroup.
  users.groups = lib.mapAttrs (_name: _: { }) (lib.filterAttrs (_: u: u.isSystemUser) cfg.users);
}
