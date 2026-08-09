{ inputs }:
_: {
  flake.modules.darwin.homebrew =
    {
      config,
      lib,
      ...
    }:
    {
      imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];
      options.mine.darwin.brew = {
        enable = lib.mkEnableOption "nix-homebrew";
        user = lib.mkOption {
          type = lib.types.str;
          description = "Primary user for homebrew operations.";
        };
        taps = lib.mkOption {
          type = lib.types.attrsOf lib.types.raw;
          default = { };
          description = "Homebrew tap inputs (homebrew-core, homebrew-cask, etc.).";
        };
        brews = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Homebrew formulae to install.";
        };
        casks = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Homebrew casks to install.";
        };
        enableRosetta = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Rosetta 2 for x86_64 homebrew on Apple Silicon.";
        };
      };
      config = lib.mkIf config.mine.darwin.brew.enable {
        nix-homebrew = {
          enable = true;
          inherit (config.mine.darwin.brew)
            user
            enableRosetta
            taps
            ;
        };
        homebrew = {
          inherit (config.mine.darwin.brew)
            brews
            casks
            ;
        };
      };
    };
}
