{ lib, ... }:
{
  options.mine = {
    hostName = lib.mkOption {
      type = lib.types.str;
      description = "The machine's hostname.";
    };

    user = {
      username = lib.mkOption {
        type = lib.types.str;
        description = "The primary user's username.";
      };
      fullName = lib.mkOption {
        type = lib.types.str;
        description = "The primary user's full name.";
      };
      email = lib.mkOption {
        type = lib.types.str;
        description = "The primary user's email address.";
      };
    };

    location = {
      timezone = lib.mkOption {
        type = lib.types.str;
        description = "The machine's timezone.";
      };
      latitude = lib.mkOption {
        type = lib.types.float;
        description = "The machine's latitude.";
      };
      longitude = lib.mkOption {
        type = lib.types.float;
        description = "The machine's longitude.";
      };
    };

    network.tailscale.enable = lib.mkEnableOption "Tailscale";

    # Secret store wiring. Supplied by the leaf per host; only consumed when
    # `enable` is true (personal/work bring-up, milestone 3+).
    agenix = {
      enable = lib.mkEnableOption "agenix-rekey secret provisioning";
      masterIdentities = lib.mkOption {
        type = lib.types.listOf (
          lib.types.submodule {
            options.identity = lib.mkOption {
              type = lib.types.str;
              description = "Path to the master identity (age/yubikey) file.";
            };
            options.pubkey = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Optional explicit pubkey for the identity.";
            };
          }
        );
        # Placeholder satisfying agenix-rekey's unconditional non-empty
        # assertion while `enable` is false; leaves override when enabling.
        default = [
          {
            identity = "/dev/null";
          }
        ];
        description = "Master identities (typically YubiKey age identities).";
      };
      hostPubkey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to this host's age pubkey.";
      };
      localStorageDir = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to the leaf's committed rekeyed/ output directory.";
      };
      generatedSecretsDir = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to the leaf's generated/ secrets directory.";
      };
    };
  };
}
