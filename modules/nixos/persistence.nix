{ inputs }:
{
  config,
  lib,
  ...
}:
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  config = {
    environment = {
      sessionVariables.NIX_INDEX_DATABASE = "/var/cache/nix-index/";
      persistence."/nix/persist" = {
        hideMounts = true;
        directories = [
          "/etc/ssh"
          "/etc/NetworkManager/system-connections"
          "/var/lib/nixos"
          "/var/cache/nix-index"
          "/root"
        ]
        ++ lib.mapAttrsToList (_name: u: {
          directory = "/home/${u.username}";
          user = u.username;
          group = "users";
          mode = "0700";
        }) (lib.filterAttrs (_: u: !u.isSystemUser) config.mine.users);
        files = [ "/etc/machine-id" ];
      };
    };
  };
}
