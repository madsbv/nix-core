# SSH known_hosts for well-known forge services and fleet nodes. The option
# declarations live in `modules/options.nix` (so the generic `mine` mirror into
# Home Manager evaluations stays consistent); this module only wires the NixOS
# behavior. Personal host keys and node lists come from the leaf via
# `mine.ssh.knownHosts`.
{ config, lib, ... }:
let
  cfg = config.mine.ssh.knownHosts;
in
{
  config.programs.ssh.knownHosts = lib.mkIf cfg.enable (
    {
      "github.com".publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
      "gitlab.com".publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf";
      "git.sr.ht".publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMZvRd4EtM7R+IHVMWmDkVU3VLQTSwQDSAvW0t2Tkj60";
    }
    // lib.optionalAttrs (cfg.hostKeyDir != null) (
      builtins.listToAttrs (
        map (host: {
          name = host;
          value = {
            publicKeyFile = "${cfg.hostKeyDir}/ssh_host_ed25519_key.pub.${host}";
          };
        }) cfg.nodes
      )
    )
  );
}
