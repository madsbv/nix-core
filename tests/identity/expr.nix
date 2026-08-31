# Snapshot of the `mine.*` identity framework: evaluate the options module
# against a representative leaf identity and snapshot the resolved `mine` value.
# Exercises the user submodule, the primaryUser -> user alias, the Quad9 DNS
# preset, and the stateVersion fallback resolution — all JSON-safe.
{ lib }:

let
  eval = lib.evalModules {
    modules = [
      # `assertions`/`warnings` are provided by the NixOS / nix-darwin module
      # systems, not `lib.evalModules`; declare them here so `options.nix` (which
      # asserts on the primary user and warns on an unset stateVersion) evaluates
      # standalone.
      {
        options = {
          assertions = lib.mkOption {
            type = lib.types.listOf lib.types.raw;
            default = [ ];
          };
          warnings = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        };
      }
      ../../modules/options.nix
      {
        mine = {
          hostName = "test-host";
          flakeRoot = "/home/alice/fleet/personal";
          primaryUser = "alice";
          users = {
            alice = {
              fullName = "Alice Example";
              email = "alice@example.com";
              sshAuthorizedKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIexample alice@example" ];
            };
            bob = {
              fullName = "Bob Example";
              email = "bob@example.com";
            };
            deploy = {
              isSystemUser = true;
            };
          };
          location = {
            timezone = "Europe/Copenhagen";
            latitude = 55.6761;
            longitude = 12.5683;
          };
          network.dns.quad9MalwareBlocking = true;
          system.stateVersion = "25.05";
        };
      }
    ];
  };
in
eval.config.mine
