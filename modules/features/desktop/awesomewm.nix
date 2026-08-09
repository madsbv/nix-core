_: {
  flake.modules.nixos.awesomewm = _: {
    services.xserver.windowManager.awesome = {
      enable = true;
      luaModules = [ ];
    };
  };

  flake.modules.homeManager.awesomewm =
    { lib, ... }:
    {
      xdg.configFile = {
        "awesome/rc.lua".source = ./rc.lua;
        "awesome/rules.lua".source = lib.mkDefault ./rules.lua;
      };
    };
}
