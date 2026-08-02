_: {
  flake.modules.homeManager.lua = { pkgs, ... }: {
    home.packages =
      with pkgs;
      [
        luajit
        lua-language-server
      ]
      ++ (with pkgs.luajitPackages; [
        luarocks
      ]);
  };
}
