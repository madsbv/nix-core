# User framework: turns the `mine.users` option into NixOS users, per-user
# Home Manager configs, and (when agenix is enabled) per-user SSH identity
# secrets. Replaces the old `systemModules/users` + `nixosModules/users`
# wiring: identity lives in `mine.*` (leaf-provided), no `flake-root` /
# `specialArgs` plumbing, no personal values in core.
#
# The primary user's Home Manager modules are threaded in by the builders
# (`mkNixosHost` feeds `profiles`/`modules` into `mine.users.<primary>`);
# every other user gets theirs from `mine.users.<name>.homeManagerModules`
# (leaf-provided, possibly via the builders' `users` parameter).
{ config, lib, ... }:
let
  cfg = config.mine;

  # Users that get a Home Manager config: non-system users that declare any.
  hmUsers = lib.filterAttrs (_: u: !u.isSystemUser && u.homeManagerModules != [ ]) cfg.users;

  # Human users get `wheel` (for sudo) on top of their declared groups.
  humanGroups = u: u.extraGroups ++ lib.optionals (!u.isSystemUser) [ "wheel" ];

  ageSecretsDir = cfg.agenix.secretsDir;
  hostKeyName = cfg.hostName;
in
{
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

  # Home Manager, when present (always for builder-built hosts): per-user
  # config with the system evaluation's `mine` values mirrored into the nested
  # Home Manager evaluation (see lib/mkNixosHost.nix).
  home-manager.users = lib.mkIf (config ? home-manager) (
    lib.mapAttrs (_name: u: {
      imports = [
        {
          inherit (config) mine;
        }
        {
          home.stateVersion = lib.mkDefault "25.05";
        }
      ]
      ++ u.homeManagerModules;
    }) hmUsers
  );

  # Per-user SSH identity secrets (agenix-rekey), same layout as the old repo:
  #   secrets/ssh/id_ed25519.<hostname>.<username>.age
  # Mechanism only — gated on `mine.agenix.enable`, path derived from the
  # leaf's `mine.agenix.secretsDir`.
  age.secrets = lib.mkIf (cfg.agenix.enable && ageSecretsDir != null) (
    lib.mapAttrs' (
      _: u:
      lib.nameValuePair "id.${hostKeyName}.${u.username}" {
        rekeyFile = "${ageSecretsDir}/ssh/id_ed25519.${hostKeyName}.${u.username}.age";
        owner = u.username;
      }
    ) cfg.users
  );
}
