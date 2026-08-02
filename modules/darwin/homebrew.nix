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
      };
      config = lib.mkIf config.mine.darwin.brew.enable {
        nix-homebrew = {
          enable = true;
          user = config.mine.darwin.brew.user;
          taps = config.mine.darwin.brew.taps;
          brews = config.mine.darwin.brew.brews;
          casks = config.mine.darwin.brew.casks;
        };
      };
    };
}
