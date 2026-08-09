{ inputs }:
let
  # Shared agenix-rekey wiring, reused by every module class.
  mkAgenixModule =
    {
      imports,
      self,
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
        {
          rekey = {
            hostPubkey = config.mine.agenix.hostPubkey;
            localStorageDir =
              if config.mine.agenix.localStorageDir != null then
                config.mine.agenix.localStorageDir
              else
                self + "/secrets/rekeyed/${config.mine.hostName}";
            secretsDir =
              if config.mine.agenix.secretsDir != null then config.mine.agenix.secretsDir else self + "/secrets";
            generatedSecretsDir =
              if config.mine.agenix.generatedSecretsDir != null then
                config.mine.agenix.generatedSecretsDir
              else
                self + "/secrets/generated";
            agePlugins = [ pkgs.age-plugin-yubikey ];
          };
        }
      ];
    };
in
{
  self,
  ...
}:
{
  flake.modules = {
    nixos.agenix = mkAgenixModule {
      imports = [
        inputs.agenix.nixosModules.age
        inputs.agenix-rekey.nixosModules.default
      ];
      inherit self;
    };

    homeManager.agenix = mkAgenixModule {
      imports = [
        inputs.agenix.homeManagerModules.age
        inputs.agenix-rekey.homeManagerModules.default
      ];
      inherit self;
    };

    darwin.agenix = mkAgenixModule {
      imports = [
        inputs.agenix.darwinModules.age
        inputs.agenix-rekey.darwinModules.default
      ];
      inherit self;
    };
  };
}
