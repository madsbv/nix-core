# Shared per-user wiring for NixOS and nix-darwin: the per-user Home Manager
# configs (mirroring the system-side `mine` values and pinning
# `home.stateVersion`) and the per-user SSH identity agenix secrets. Both
# `users.nix` (NixOS) and `users-darwin.nix` import this; only the `users.users`
# account definition differs between the platforms (groups/extraGroups on NixOS
# vs uid/home/knownUsers on Darwin).
{ config, lib, ... }:
let
  cfg = config.mine;

  # Users that get a Home Manager config: non-system users that declare any.
  hmUsers = lib.filterAttrs (_: u: !u.isSystemUser && u.homeManagerModules != [ ]) cfg.users;

  hostKeyName = cfg.hostName;
in
{
  config = {
    # Home Manager, when present (always for builder-built hosts): per-user
    # config with the system evaluation's `mine` values mirrored into the nested
    # Home Manager evaluation via `modules/_hm-mirror.nix` (pruned to the options
    # the HM eval actually declares, so system-only `mine.*` options can't break
    # HM evals).
    home-manager.users = lib.mkIf (config ? home-manager) (
      lib.mapAttrs (_name: u: {
        imports = [
          (import ../_hm-mirror.nix { osMine = cfg; })
          {
            home.stateVersion = lib.mkDefault config.mine.system.stateVersionHomeFinal;
          }
        ]
        ++ u.homeManagerModules;
      }) hmUsers
    );

    # Per-user SSH identity secrets (agenix-rekey), same layout as the old repo:
    #   secrets/ssh/id_ed25519.<hostname>.<username>.age
    # Path derived from the leaf's `mine.agenix.secretsDir`.
    age.secrets = lib.mkIf (cfg.agenix.secretsDir != null) (
      lib.mapAttrs' (
        _: u:
        lib.nameValuePair "id.${hostKeyName}.${u.username}" {
          rekeyFile = "${cfg.agenix.secretsDir}/ssh/id_ed25519.${hostKeyName}.${u.username}.age";
          owner = u.username;
        }
      ) cfg.users
    );
  };
}
