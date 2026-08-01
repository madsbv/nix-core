_: {
  flake.modules.homeManager.ssh = _: {
    programs.ssh = {
      enable = true;
      extraConfig = ''
        ServerAliveInterval 60
      '';
    };
  };
}
