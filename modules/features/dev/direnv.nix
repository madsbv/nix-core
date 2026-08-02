_: {
  flake.modules.homeManager.direnv = { pkgs, ... }: {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    home.packages = [ pkgs.direnv-instant ];
  };
}
