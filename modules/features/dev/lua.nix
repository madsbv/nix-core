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
    home.sessionVariables.LUA_LANGUAGE_SERVER_INSTALL_DIR = "${pkgs.lua-language-server}";
  };
}
