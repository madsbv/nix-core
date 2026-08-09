{ inputs }:
let
  # Shared agenix(-rekey) wiring, reused by every module class. The classes
  # only differ in which agenix/agenix-rekey modules they import, so the rekey
  # config is defined once here. `hostKeyIdentityPaths` additionally derives
  # agenix `identityPaths` from the NixOS openssh host keys; homeManager/darwin
  # don't expose a host-key store, so they leave it unset.
  mkAgenixModule =
    {
      imports,
      hostKeyIdentityPaths ? false,
    }:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      inherit imports;

      # agenix-rekey asserts `rekey.masterIdentities != []` unconditionally,
      # so always provide it (the leaf overrides it when enabling).
      config.age = lib.mkMerge [
        {
          rekey = {
            masterIdentities = lib.mkDefault config.mine.agenix.masterIdentities;
            storageMode = "local";
          };
        }
        (lib.mkIf config.mine.agenix.enable {
          rekey = {
            hostPubkey = config.mine.agenix.hostPubkey;
            localStorageDir = config.mine.agenix.localStorageDir;
            generatedSecretsDir = config.mine.agenix.generatedSecretsDir;
            agePlugins = [ pkgs.age-plugin-yubikey ];
          }
          // lib.optionalAttrs hostKeyIdentityPaths {
            identityPaths = lib.mkDefault (
              if config.services.openssh.enable or false then
                map (e: e.path) (
                  lib.filter (e: e.type == "ed25519" || e.type == "rsa") config.services.openssh.hostKeys
                )
              else
                [ ]
            );
          };
        })
      ];
    };
in
_: {
  flake.modules = {
    nixos.agenix = mkAgenixModule {
      imports = [
        inputs.agenix.nixosModules.age
        inputs.agenix-rekey.nixosModules.default
      ];
      hostKeyIdentityPaths = true;
    };

    homeManager.agenix = mkAgenixModule {
      imports = [
        inputs.agenix.homeManagerModules.age
        inputs.agenix-rekey.homeManagerModules.default
      ];
    };

    darwin.agenix = mkAgenixModule {
      imports = [
        inputs.agenix.darwinModules.age
        inputs.agenix-rekey.darwinModules.default
      ];
    };
  };
}
