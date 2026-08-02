{ lib, config, ... }:
let
  # Shared submodule for every user (the primary user and any additional users,
  # including robot/service accounts). Identity drives value-based features
  # (AD-4); the machine-level fields live on `mine` directly, not per-user.
  userSubmodule = { name, ... }: {
    options = {
      username = lib.mkOption {
        type = lib.types.str;
        default = name;
        description = "Username; defaults to the attr key of `mine.users`.";
      };
      fullName = lib.mkOption {
        type = lib.types.str;
        default = name;
        description = "Full name, used by git and other identity-driven features.";
      };
      email = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Email address; may be null for robot accounts.";
      };
      isSystemUser = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether this is a robot/system account (no home dir, no Home Manager).";
      };
      uid = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Optional fixed uid for this user.";
      };
      gid = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Optional fixed gid for this user.";
      };
      shell = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Login shell; set e.g. `/run/current-system/sw/bin/nologin` for locked-down robots.";
      };
      extraGroups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional groups beyond the defaults (`wheel` for human users).";
      };
      sshAuthorizedKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "SSH public keys authorized for this user.";
      };
      initialHashedPassword = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Initial hashed password; null means key-only / no password.";
      };
      homeManagerModules = lib.mkOption {
        type = lib.types.listOf lib.types.raw;
        default = [ ];
        description = "Home Manager modules for this user. Ignored for system users.";
      };
    };
  };
in
{
  options.mine = {
    hostName = lib.mkOption {
      type = lib.types.str;
      description = "The machine's hostname.";
    };

    primaryUser = lib.mkOption {
      type = lib.types.str;
      description = "Username of the primary user; must be a key of `mine.users`.";
    };

    users = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule userSubmodule);
      default = { };
      description = ''
        Per-user identity and configuration, keyed by username. Every user of the
        machine lives here: the primary user (selected by `mine.primaryUser`),
        other humans (with their own Home Manager config), and robot/service
        accounts (isSystemUser, locked-down shell, key-only SSH).
      '';
    };

    user = lib.mkOption {
      type = lib.types.submodule userSubmodule;
      description = "The primary user — alias of mine.users.<mine.primaryUser>.";
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

    # SSH known_hosts for forge services + fleet nodes (wired by
    # `modules/system/keys.nix`). Declared here so the generic `mine` mirror
    # into Home Manager evaluations stays consistent.
    ssh.knownHosts = {
      enable = lib.mkEnableOption "SSH known_hosts for known services and fleet nodes";
      hostKeyDir = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Directory of host pubkeys named ssh_host_ed25519_key.pub.<hostname> (leaf-owned).";
      };
      nodes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Fleet hostnames whose host keys are pinned from `hostKeyDir`.";
      };
    };

    # Remote building (wired by `modules/system/builder.nix`).
    remoteBuilder = {
      enableLocalBuilder = lib.mkEnableOption "local `builder` user for remote builds";
      enableRemoteBuilders = lib.mkEnableOption "use of other nodes as remote builders";
      authorizedKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "SSH public keys authorized for the `builder` user.";
      };
      buildMachines = lib.mkOption {
        type = lib.types.listOf lib.types.raw;
        default = [ ];
        description = "nix.buildMachines entries for remote builder nodes.";
      };
    };

    system = {
      persistence.enable = lib.mkEnableOption "impermanence-based `/nix/persist` persistence" // {
        default = true;
      };
      autoUpgrade = {
        enable = lib.mkEnableOption "system.autoUpgrade";
        flake = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Flake to auto-upgrade from (the leaf's own repo).";
        };
      };
    };

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
      secretsDir = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to the leaf's secrets/ directory (source of encrypted .age files).";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (config.mine.users ? ${config.mine.primaryUser}) {
      mine.user = config.mine.users.${config.mine.primaryUser};
    })
    # Inside a Home Manager evaluation, `mine.user` must resolve to the
    # *current* user, not the host's primary. The system-eval mirror carries the
    # primary's value (see modules/system/users.nix), so force the per-user
    # resolution here.
    (lib.mkIf (config ? home && config.mine.users ? ${config.home.username}) {
      mine.user = lib.mkForce config.mine.users.${config.home.username};
    })
    {
      assertions = [
        {
          assertion = config.mine.users ? ${config.mine.primaryUser};
          message = "mine.primaryUser '${config.mine.primaryUser}' must be a key of mine.users";
        }
      ];
    }
  ];
}
