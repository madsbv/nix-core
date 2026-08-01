_: {
  flake.modules.homeManager.shell = _: {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      shellAliases = {
        ll = "ls -la";
        la = "ls -A";
      };
    };

    programs.starship.enable = true;
    programs.fzf.enable = true;
    programs.zoxide.enable = true;
    programs.eza.enable = true;
    programs.bat.enable = true;
  };
}
