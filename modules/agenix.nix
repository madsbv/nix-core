{ inputs }:
let
  # Shared agenix-rekey wiring, reused by every module class.
  mkAgenixModule =
    {
      imports,
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
