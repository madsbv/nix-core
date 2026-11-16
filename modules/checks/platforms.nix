# Package platform support: every package the profiles install must be
# available on the system it is installed on. Evaluated per class over the
# union of all profiles, so a package added anywhere fails `nix flake check`
# here instead of in a leaf host.
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
  allProfiles = lib.attrValues config.flake.profiles;
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
          failures = unavailable packages;
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
      homeCfg = config.flake.lib.mkHomeConfig {
        inherit system;
        username = "check";
        profiles = allProfiles;
        identity = [ stubIdentity ];
      };
    in
    {
      checks = {
        platform-home = check "home" homeCfg.config.home.packages;
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        platform-nixos =
          check "nixos"
            (config.flake.lib.mkNixosHost {
              inherit system;
              hostname = "platform-check";
              profiles = allProfiles;
              identity = [ stubIdentity ];
            }).config.environment.systemPackages;
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        platform-darwin =
          check "darwin"
            (config.flake.lib.mkDarwinHost {
              inherit system;
              hostname = "platform-check";
              profiles = allProfiles;
              identity = [ stubIdentity ];
            }).config.environment.systemPackages;
      };
    };
}
