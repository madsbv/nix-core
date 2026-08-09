_: {
  flake.modules.nixos.tailscale =
    {
      config,
      lib,
      ...
    }:
    {
      options.mine.network.tailscale.authKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to an agenix-decrypted tailscale auth key. When null, interactive login is used.";
      };
      config = {
        services.tailscale = {
          enable = true;
          extraUpFlags = [ "--ssh" ];
        }
        // lib.optionalAttrs (config.mine.network.tailscale.authKeyFile != null) {
          authKeyFile = config.mine.network.tailscale.authKeyFile;
        };
      };
    };

  flake.modules.darwin.tailscale =
    {
      config,
      lib,
      ...
    }:
    {
      options.mine.network.tailscale.authKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to an agenix-decrypted tailscale auth key. When null, interactive login is used.";
      };
      config = {
        services.tailscale = {
          enable = true;
          extraUpFlags = [ "--ssh" ];
        }
        // lib.optionalAttrs (config.mine.network.tailscale.authKeyFile != null) {
          authKeyFile = config.mine.network.tailscale.authKeyFile;
        };
      };
    };

  flake.modules.homeManager.tailscale =
    {
      pkgs,
      ...
    }:
    {
      config = {
        home.packages = [ pkgs.tailscale ];
      };
    };
}
