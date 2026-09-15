# Tailscale wiring. The system-side `services.tailscale` config cannot be
# shared: nix-darwin's tailscale module only has `enable`/`package`/
# `overrideLocalDns` (no `extraUpFlags`/authKeyFile — on macOS login happens
# via the GUI app), so only NixOS gets the flag surface; darwin just enables
# the daemon. Both declare the same `mine.network.tailscale` option surface.
# Home Manager can only install the CLI, not run the daemon, so it gets a
# small package-only module.
_:
let
  tailscaleOptions =
    { lib, ... }:
    {
      authKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to an agenix-decrypted tailscale auth key. When null, interactive login is used.";
      };
      hostname = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Explicit tailscale node name. Defaults to the system hostname.";
      };
      tags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Tailscale tags for this node (e.g. tag:server).";
      };
      advertiseRoutes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Subnet routes to advertise (CIDR strings).";
      };
      advertiseExitNode = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Advertise this node as an exit node.";
      };
    };
in
{
  flake.modules.nixos.tailscale =
    {
      config,
      lib,
      ...
    }:
    {
      options.mine.network.tailscale = tailscaleOptions { inherit lib; };
      config = {
        services.tailscale = {
          enable = true;
          extraUpFlags = [
            "--ssh"
          ]
          ++ lib.optionals (config.mine.network.tailscale.hostname != null) [
            "--hostname=${config.mine.network.tailscale.hostname}"
          ]
          ++ map (t: "--advertise-tags=${t}") config.mine.network.tailscale.tags
          ++ map (r: "--advertise-routes=${r}") config.mine.network.tailscale.advertiseRoutes
          ++ lib.optionals config.mine.network.tailscale.advertiseExitNode [
            "--advertise-exit-node"
          ];
        }
        // lib.optionalAttrs (config.mine.network.tailscale.authKeyFile != null) {
          authKeyFile = config.mine.network.tailscale.authKeyFile;
        };
      };
    };

  flake.modules.darwin.tailscale =
    {
      lib,
      ...
    }:
    {
      # Same option surface as NixOS so the pruning HM mirror sees a consistent
      # shape; only `enable` is applied on darwin.
      options.mine.network.tailscale = tailscaleOptions { inherit lib; };
      services.tailscale.enable = lib.mkDefault true;
    };

  flake.modules.homeManager.tailscale =
    { pkgs, ... }:
    {
      config = {
        home.packages = [ pkgs.tailscale ];
      };
    };
}
