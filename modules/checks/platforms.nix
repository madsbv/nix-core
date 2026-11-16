# Package platform support: every package the core profiles install must be
# available on the system it is installed on.
#
# The core profiles are evaluated together (they coexist in real hosts), with
# a stub identity. Leaf-owned profiles are not included: they are alternatives
# to each other (e.g. personal-desktop vs personal-darwin) and assume host
# context, and leaf host evaluations already fail on unsupported packages.
#
# Covers `home.packages` (Home Manager, all systems), `environment.systemPackages`
# for NixOS (Linux systems) and nix-darwin (Darwin systems). Services are not
# covered yet.
{ config, lib, ... }:
let
  stubIdentity = {
    mine = {
      hostName = "platform-check";
      primaryUser = "check";
      flakeRoot = "/tmp/platform-check";
      users.check = {
        email = "check@example.com";
        fullName = "Check";
      };
    };
  };
  # Keep in sync with modules/profiles/. A core profile missing here is not
  # platform-checked.
  coreProfiles = [
    "base"
    "desktop"
    "dev"
    "editors"
    "shell"
    "system"
    "terminal"
  ];
  profiles = map (n: config.flake.profiles.${n}) coreProfiles;
in
{
  perSystem =
    { pkgs, system, ... }:
    let
      hostPlatform = pkgs.stdenv.hostPlatform;
      unavailable =
        packages: map (p: p.name) (lib.filter (p: !lib.meta.availableOn hostPlatform p) packages);
      check =
        name: packages:
        let
          failureFile = pkgs.writeText "${name}-failures" (lib.concatStringsSep "\n" (unavailable packages));
        in
        pkgs.runCommandLocal "platform-${name}" { } ''
          if [ -s ${failureFile} ]; then
            echo "packages unavailable on ${system}:" >&2
            cat ${failureFile} >&2
            exit 1
          fi
          touch $out
        '';
    in
    {
      checks = {
        platform-home =
          check "home"
            (config.flake.lib.mkHomeConfig {
              inherit system;
              username = "check";
              inherit profiles;
              identity = [ stubIdentity ];
            }).config.home.packages;
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        platform-nixos =
          check "nixos"
            (config.flake.lib.mkNixosHost {
              inherit system profiles;
              hostname = "platform-check";
              identity = [ stubIdentity ];
            }).config.environment.systemPackages;
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        platform-darwin =
          check "darwin"
            (config.flake.lib.mkDarwinHost {
              inherit system profiles;
              hostname = "platform-check";
              identity = [ stubIdentity ];
            }).config.environment.systemPackages;
      };
    };
}
