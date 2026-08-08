_: {
  flake.modules.homeManager.shell =
    {
      lib,
      ...
    }:
    {
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        shellAliases = lib.mkDefault {
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

  flake.modules.nixos.shell =
    {
      lib,
      pkgs,
      ...
    }:
    {
      programs.zsh = {
        enable = true;
        syntaxHighlighting = {
          enable = lib.mkDefault true;
          highlighters = lib.mkDefault [
            "main"
            "brackets"
          ];
        };
      };
      users.defaultUserShell = lib.mkForce pkgs.zsh;
    };
}
