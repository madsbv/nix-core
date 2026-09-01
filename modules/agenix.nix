{ inputs }:
let
  # Shared agenix-rekey wiring, reused by every module class.
  mkAgenixModule =
    {
      imports,
      self,
      homeManager ? false,
    }:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Per-host directory key for the rekeyed/generated secret stores.
      # System-level (NixOS / nix-darwin) secrets key on the hostname; Home
      # Manager-level secrets key on hostname + username. Without the username
      # suffix the integrated HM eval — which agenix-rekey auto-discovers as its
      # own node sharing the hostname — clobbers the system-level secrets that
      # target the same directory.
      dirName =
        if homeManager then
          "${config.mine.hostName}-user-${config.home.username}"
        else
          config.mine.hostName;
    in
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
        (lib.mkIf (config.mine.agenix.hostPubkey != null) {
          rekey = {
            hostPubkey = config.mine.agenix.hostPubkey;
            localStorageDir =
              if config.mine.agenix.localStorageDir != null then
                config.mine.agenix.localStorageDir
              else
                self + "/secrets/rekeyed/${dirName}";
            secretsDir =
              if config.mine.agenix.secretsDir != null then config.mine.agenix.secretsDir else self + "/secrets";
            generatedSecretsDir =
              if config.mine.agenix.generatedSecretsDir != null then
                config.mine.agenix.generatedSecretsDir
              else
                self + "/secrets/generated/${dirName}";
            agePlugins = [ pkgs.age-plugin-yubikey ];
          };
        })
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
      homeManager = true;
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
