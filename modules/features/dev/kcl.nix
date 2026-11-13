_: {
  flake.modules.homeManager.kcl = { pkgs, ... }: {
    home.packages = [
      pkgs.kcl
      pkgs.kcl-language-server
    ];
  };
}
