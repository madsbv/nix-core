_: {
  flake.modules.homeManager.terminal = _: {
    programs.alacritty = {
      enable = true;
      settings = {
        window.padding = {
          x = 4;
          y = 4;
        };
        font = {
          size = 12;
          normal.family = "JetBrains Mono";
        };
      };
    };
    home.sessionVariables.TERMINAL = "alacritty";
  };
}
