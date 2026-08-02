_: {
  flake.modules.homeManager.gh = _: {
    programs.gh = {
      enable = true;
      settings.editor = "vim";
    };
  };
}
