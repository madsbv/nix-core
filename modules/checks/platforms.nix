# Package platform support: every package a profile installs must be available
# on the system it is installed on. Each profile is evaluated on its own, since
# profiles can be alternatives (e.g. desktop vs darwin personal profiles) whose
# union is not a valid configuration.
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
  profiles = lib.attrValues config.flake.profiles;
in
{
  perSystem =
    { pkgs, system, ... }:
    let
      hostPlatform = pkgs.stdenv.hostPlatform;
      # Failures for every profile, as "<profile>: <package>" lines.
      failuresFor =
        packagesOf:
        lib.unique (
          lib.concatMap (
            profile:
            map (name: "${profile.name}: ${name}") (
              map (p: p.name) (lib.filter (p: !lib.meta.availableOn hostPlatform p) (packagesOf profile))
            )
          ) profiles
        );
      check =
        name: failures:
        let
          failureFile = pkgs.writeText "${name}-failures" (lib.concatStringsSep "\n" failures);
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
        platform-home = check "home" (
          failuresFor (
            profile:
            (config.flake.lib.mkHomeConfig {
              inherit system;
              username = "check";
              profiles = [ config.flake.profiles.base ] ++ lib.optional (profile.name != "base") profile;
              identity = [ stubIdentity ];
            }).config.home.packages
          )
        );
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        platform-nixos = check "nixos" (
          failuresFor (
            profile:
            (config.flake.lib.mkNixosHost {
              inherit system;
              hostname = "platform-check";
              profiles = [ config.flake.profiles.base ] ++ lib.optional (profile.name != "base") profile;
              identity = [ stubIdentity ];
            }).config.environment.systemPackages
          )
        );
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        platform-darwin = check "darwin" (
          failuresFor (
            profile:
            (config.flake.lib.mkDarwinHost {
              inherit system;
              hostname = "platform-check";
              profiles = [ config.flake.profiles.base ] ++ lib.optional (profile.name != "base") profile;
              identity = [ stubIdentity ];
            }).config.environment.systemPackages
          )
        );
      };
    };
}
