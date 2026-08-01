{ inputs, ... }:
{
  flake.modules = {
    # NixOS: agenix + agenix-rekey wiring. Consumed by the builders and the
    # base composite; active only when `mine.agenix.enable` is true.
    nixos.agenix =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        imports = [
          inputs.agenix.nixosModules.age
          inputs.agenix-rekey.nixosModules.default
        ];

        # agenix-rekey asserts `rekey.masterIdentities != []` unconditionally,
        # so always provide it (the leaf overrides it when enabling).
        config.age = lib.mkMerge [
          {
            rekey.masterIdentities = lib.mkDefault config.mine.agenix.masterIdentities;
          }
          (lib.mkIf config.mine.agenix.enable {
            identityPaths = lib.mkDefault (
              if config.services.openssh.enable or false then
                map (e: e.path) (
                  lib.filter (e: e.type == "ed25519" || e.type == "rsa") config.services.openssh.hostKeys
                )
              else
                [ ]
            );

            rekey = {
              hostPubkey = config.mine.agenix.hostPubkey;
              storageMode = "local";
              localStorageDir = config.mine.agenix.localStorageDir;
              generatedSecretsDir = config.mine.agenix.generatedSecretsDir;
              agePlugins = [ pkgs.age-plugin-yubikey ];
            };
          })
        ];
      };

    homeManager.agenix =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        imports = [
          inputs.agenix.homeManagerModules.age
          inputs.agenix-rekey.homeManagerModules.default
        ];

        config.age = lib.mkMerge [
          {
            rekey.masterIdentities = lib.mkDefault config.mine.agenix.masterIdentities;
          }
          (lib.mkIf config.mine.agenix.enable {
            rekey = {
              hostPubkey = config.mine.agenix.hostPubkey;
              storageMode = "local";
              localStorageDir = config.mine.agenix.localStorageDir;
              generatedSecretsDir = config.mine.agenix.generatedSecretsDir;
              agePlugins = [ pkgs.age-plugin-yubikey ];
            };
          })
        ];
      };

    darwin.agenix =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        imports = [
          inputs.agenix.darwinModules.age
          inputs.agenix-rekey.darwinModules.default
        ];

        config.age = lib.mkMerge [
          {
            rekey.masterIdentities = lib.mkDefault config.mine.agenix.masterIdentities;
          }
          (lib.mkIf config.mine.agenix.enable {
            rekey = {
              hostPubkey = config.mine.agenix.hostPubkey;
              storageMode = "local";
              localStorageDir = config.mine.agenix.localStorageDir;
              generatedSecretsDir = config.mine.agenix.generatedSecretsDir;
              agePlugins = [ pkgs.age-plugin-yubikey ];
            };
          })
        ];
      };
  };
}
