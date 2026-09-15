{ lib, config, ... }:
let
  # Central default for `stateVersion` (NixOS / Home Manager). Leaves are
  # encouraged to override it per host via `mine.system.stateVersion`; when they
  # don't, this default is used and a warning is emitted.
  defaultStateVersion = "25.05";

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

    flakeRoot = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Absolute filesystem path to the leaf flake root for this host.
        Used to derive convention-based paths for agenix secret directories.
        Set per-host because different machines may clone the flake to different
        locations (/etc/nixos/nix, ~/.config/nix/, etc.). Null means the
        convention-based paths are not available.";
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

    network.dns = {
      servers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "DNS servers to prepend to the system resolver.";
      };
      quad9MalwareBlocking = lib.mkEnableOption "Quad9 + Cloudflare malware-blocking DNS servers";
    };

    # SSH known_hosts for forge services + fleet nodes (wired by
    # `modules/system/keys.nix`). Declared here so the generic `mine` mirror
    # into Home Manager evaluations stays consistent.
    ssh.knownHosts = {
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

    # SSH client signing (wired by `features/dev/ssh.nix`).
    ssh.signingKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to SSH key for commit signing. Set in the leaf host identity; when non-null, programs.git.signing is enabled.";
    };

    # Remote building (wired by `modules/system/builder.nix`).
    remoteBuilder = {
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

    prefetch = {
      flake = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to the leaf flake to prefetch from.";
      };
      target = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Flake output attribute to build, e.g. nixosConfigurations.myhost.config.system.build.toplevel.";
      };
      inputs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Flake inputs to update before building (e.g. [\"core\" \"nixpkgs\"]); empty = update all.";
      };
      schedule = lib.mkOption {
        type = lib.types.str;
        default = "daily";
        description = "systemd OnCalendar / launchd StartCalendarInterval schedule.";
      };
    };

    system = {
      autoUpgrade = {
        flake = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Flake to auto-upgrade from (the leaf's own repo).";
        };
      };

      # Package diff on activation (wired by `modules/system/update-diff.nix`).
      updateDiff = {
        command = lib.mkOption {
          type = lib.types.nullOr lib.types.singleLineStr;
          default = null;
          description = "Diff command; the update-diff module resolves a `dix`/`nvd` default.";
        };
        text = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Diff script snippet (composed by the update-diff module).";
        };
      };

      # Register the flake a system was built with (wired by
      # `modules/system/register-flake.nix`).
      registerFlake = {
        flake = lib.mkOption {
          type = lib.types.nullOr lib.types.raw;
          default = null;
          description = "The leaf's own flake, so the running machine can introspect its configuration.";
        };
        registerSelf = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Add the flake the system was built with to `nix.registry` as `self`.";
        };
      };

      # stateVersion, overridable per host. Core warns and falls back to its
      # default when a host leaves it unset; `stateVersionFinal` is the derived
      # value that NixOS / Home Manager wiring consumes.
      stateVersion = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Per-host stateVersion override (set in the host's identity). When unset, core's default (${defaultStateVersion}) is used and a warning is emitted.";
      };
      stateVersionFinal = lib.mkOption {
        type = lib.types.str;
        description = "Resolved stateVersion (read-only; derived from `mine.system.stateVersion`).";
      };
      # Home Manager has its own `home.stateVersion`, historically tracked
      # independently of NixOS `system.stateVersion` (the old config pinned HM to
      # "23.11" while NixOS hosts were on "24.05"). Keep the two separable so
      # per-host values stay faithful to the old config.
      homeStateVersion = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Per-host Home Manager stateVersion override (set in the host's identity). When unset, `mine.system.stateVersion` is used.";
      };
      stateVersionHomeFinal = lib.mkOption {
        type = lib.types.str;
        description = "Resolved Home Manager stateVersion (read-only; `homeStateVersion` if set, else `stateVersionFinal`).";
      };
    };

    # Nix configuration, synchronized across NixOS / nix-darwin / Home Manager
    # where sensible (wired by `modules/features/system/nix-settings.nix`).
    # `settings` and `allowUnfree` are mirrored into Home Manager evaluations
    # so the standalone and integrated HM evals get the same nix.conf knobs.
    nix = {
      settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.raw;
        default = { };
        description = "nix.conf settings shared across NixOS, nix-darwin and Home Manager.";
      };
      allowUnfree = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to allow unfree packages (`nixpkgs.config.allowUnfree`).";
      };
      gc = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to periodically garbage-collect the Nix store (NixOS / nix-darwin).";
        };
        options = lib.mkOption {
          type = lib.types.str;
          default = "--delete-older-than 30d";
          description = "Arguments passed to `nix-collect-garbage`.";
        };
      };
      optimise = {
        automatic = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to automatically optimise (hard-link) the Nix store (NixOS / nix-darwin).";
        };
      };
    };

    agenix = {
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
        # assertion; leaves override this when they use agenix.
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
    # Quad9 + Cloudflare malware-blocking DNS preset.
    (lib.mkIf config.mine.network.dns.quad9MalwareBlocking {
      mine.network.dns.servers = [
        "9.9.9.9"
        "149.112.112.112"
        "2620:fe::fe"
        "2620:fe::9"
        "1.1.1.2"
        "1.0.0.2"
        "2606:4700:4700::1112"
        "2606:4700:4700::1002"
      ];
    })

    # Resolve the per-host stateVersion: `mine.system.stateVersion` is null when
    # a leaf hasn't set it, so fall back to core's default and warn. The
    # `config ? warnings` guard keeps this safe on module systems without a
    # `warnings` option (e.g. older nix-darwin evals). Note: the `or` operator
    # only falls through on *missing* attributes, not null values, so an
    # explicit null check is required here.
    {
      mine.system.stateVersionFinal = lib.mkDefault (
        if config.mine.system.stateVersion == null then
          defaultStateVersion
        else
          config.mine.system.stateVersion
      );
    }
    {
      mine.system.stateVersionHomeFinal = lib.mkDefault (
        if config.mine.system.homeStateVersion == null then
          config.mine.system.stateVersionFinal
        else
          config.mine.system.homeStateVersion
      );
    }
    (lib.mkIf (config ? warnings && config.mine.system.stateVersion == null) {
      warnings = [
        "mine.system.stateVersion is unset on this host; using core's default (${defaultStateVersion}). Set mine.system.stateVersion per host so state-version upgrades are explicit and intentional."
      ];
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
