_: {
  flake.modules.nixos.awesomewm = _: {
    services.xserver.windowManager.awesome = {
      enable = true;
      luaModules = [ ];
    };
  };

  flake.modules.homeManager.awesomewm = _: {
    xdg.configFile."awesome/rc.lua".source = ./rc.lua;
  };
}
