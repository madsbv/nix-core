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
        masApps = lib.mkOption {
          type = lib.types.attrsOf lib.types.int;
          default = { };
          description = "Mac App Store apps to install (name → app ID).";
        };
        enableRosetta = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Rosetta 2 for x86_64 homebrew on Apple Silicon.";
        };
      };
      config = {
        nix-homebrew = {
          enable = true;
          mutableTaps = false;
          user = config.mine.darwin.brew.user;
          enableRosetta = config.mine.darwin.brew.enableRosetta;
          taps = {
            "homebrew/homebrew-core" = inputs.homebrew-core;
            "homebrew/homebrew-cask" = inputs.homebrew-cask;
            "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
            "homebrew/homebrew-services" = inputs.homebrew-services;
          }
          // config.mine.darwin.brew.taps;
        };
        homebrew = {
          enable = true;
          inherit (config.mine.darwin.brew)
            brews
            casks
            masApps
            ;
          caskArgs.no_quarantine = true;
          onActivation = {
            cleanup = "uninstall";
            upgrade = true;
          };
          enableZshIntegration = true;
        };
      };
    };
}
