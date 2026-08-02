# NixOS-specific base content, ported from the old `nixosModules/common` and
# rewritten around `mine.*`. Personal values are stripped or parameterized:
# timezone/hostname/autoUpgrade come from the leaf via `mine.*`; secret paths,
# group memberships, and the blocked-domain list are leaf concerns.
{ inputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  config = {
    time.timeZone = lib.mkDefault config.mine.location.timezone;

    # autoUpgrade targets the leaf's own repo; off by default, leaf enables.
    system.autoUpgrade = lib.mkIf config.mine.system.autoUpgrade.enable {
      flake = config.mine.system.autoUpgrade.flake;
      persistent = true;
      allowReboot = true;
      randomizedDelaySec = "45min";
    };

    nix = {
      daemonCPUSchedPolicy = "idle";
      daemonIOSchedClass = "idle";
    };

    networking = {
      hostName = lib.mkDefault config.mine.hostName;
      firewall = {
        # Allow PMTU / DHCP
        allowPing = true;
        # Keep dmesg/journalctl -k output readable by NOT logging each refused
        # connection on the open internet.
        logRefusedConnections = lib.mkDefault false;
      };
      networkmanager.enable = true;
      # Use networkd instead of the pile of shell scripts.
      useNetworkd = true;
      useDHCP = false;
      nameservers = [
        # Quad9 primary and secondary, including ipv6
        "9.9.9.9"
        "149.112.112.112"
        "2620:fe::fe"
        "2620:fe::9"
        # Cloudflare 1.1.1.1 malware blocking, primary and secondary, including ipv6
        "1.1.1.2"
        "1.0.0.2"
        "2606:4700:4700::1112"
        "2606:4700:4700::1002"
      ];
    };

    systemd = {
      # The notion of "online" is a broken concept
      network.wait-online.enable = false;
      services = {
        NetworkManager-wait-online.enable = false;

        # Do not take down the network for too long when upgrading; use
        # `systemctl restart` rather than stop + delayed start.
        systemd-networkd.stopIfChanged = false;
        systemd-resolved.stopIfChanged = false;

        # Make builds more likely to be killed than important services.
        nix-daemon.serviceConfig.OOMScoreAdjust = lib.mkDefault 250;
      };
    };

    # Internationalisation.
    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      keyMap = "us";
    };

    hardware.enableRedistributableFirmware = true;

    programs = {
      neovim = {
        enable = true;
        vimAlias = true;
        viAlias = true;
        defaultEditor = true;
      };
      git = {
        enable = true;
        lfs = {
          enable = true;
          enablePureSSHTransfer = true;
        };
      };

      # Conflicts with nix-index
      command-not-found.enable = false;
      zsh.enable = true;
      zsh.syntaxHighlighting = {
        enable = true;
        highlighters = [
          "main"
          "brackets"
        ];
      };
    };

    services = {
      openssh = {
        enable = true;
        settings = {
          X11Forwarding = false;
          KbdInteractiveAuthentication = false;
          PasswordAuthentication = false;
        };
      };

      zfs = lib.mkIf config.boot.zfs.enabled {
        autoSnapshot.enable = true;
        # Hourly for a day, daily for a week, ... up to monthly for a year.
        autoSnapshot.monthly = 3;
        autoScrub.enable = true;
      };
    };

    # Impermanence: persist state on /nix/persist. On by default; disable via
    # `mine.system.persistence.enable`. Hosts provide the /nix/persist mount.
    environment = {
      sessionVariables.NIX_INDEX_DATABASE = "/var/cache/nix-index/";
      persistence."/nix/persist" = lib.mkIf config.mine.system.persistence.enable {
        hideMounts = true;
        directories = [
          "/etc/ssh" # Entire directory so we can set neededForBoot
          "/etc/NetworkManager/system-connections"
          "/var/lib/nixos" # Persist uids/gids of users/groups
          "/var/cache/nix-index"
          "/root"
        ]
        # Whole-home persistence for every human user. Listed at the root level
        # (not `users.<name>.directories = [ "" ]`) because the bind-mount
        # rewrite of impermanence breaks on empty paths; ownership is set so
        # each home is created owned by its user.
        ++ lib.mapAttrsToList (_name: u: {
          directory = "/home/${u.username}";
          user = u.username;
          group = "users";
          mode = "0700";
        }) (lib.filterAttrs (_: u: !u.isSystemUser) config.mine.users);
        files = [ "/etc/machine-id" ];
      };
    };

    users = {
      mutableUsers = false;
      defaultUserShell = pkgs.zsh;
    };

    security.sudo = {
      execWheelOnly = true;
      extraConfig = ''
        Defaults lecture = never
      '';
    };
  };
}
