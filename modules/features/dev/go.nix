_: {
  flake.modules.homeManager.go = { config, pkgs, ... }: {
    programs.go = {
      enable = true;
      env.GOPATH = "${config.home.homeDirectory}/.go";
      telemetry.mode = "off";
    };
    home.packages = with pkgs; [
      go
      gopls
      gotools
    ];
    home.sessionPath = [ "${config.home.homeDirectory}/.go/bin" ];
  };
}
