_: {
  flake.modules.homeManager.terminal =
    {
      lib,
      ...
    }:
    {
      programs.alacritty = {
        enable = true;
        settings = {
          window.padding = {
            x = 4;
            y = 4;
          };
          font = {
            size = lib.mkDefault 12;
            normal.family = lib.mkDefault "JetBrains Mono";
          };
        };
      };
      home.sessionVariables.TERMINAL = "alacritty";
    };
}
