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
        (lib.mkIf config.mine.agenix.enable (
          let
            deriveDir =
              opt: subPath:
              if opt != null then
                opt
              else if config.mine.flakeRoot != null then
                config.mine.flakeRoot + subPath
              else
                builtins.throw ''
                  mine.flakeRoot must be set when agenix is enabled and the directory is
                  not explicitly overridden. Set mine.flakeRoot to the absolute path of
                  the leaf flake root (/etc/nixos/nix, ~/.config/nix/, etc.).
                '';
          in
          {
            rekey = {
              hostPubkey = config.mine.agenix.hostPubkey;
              localStorageDir = deriveDir config.mine.agenix.localStorageDir "/secrets/rekeyed/${config.mine.hostName}";
              secretsDir = deriveDir config.mine.agenix.secretsDir "/secrets";
              generatedSecretsDir = deriveDir config.mine.agenix.generatedSecretsDir "/secrets/generated";
              agePlugins = [ pkgs.age-plugin-yubikey ];
            };
          }
        ))
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
