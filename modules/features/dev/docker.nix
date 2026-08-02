_: {
  flake.modules.nixos.docker =
    {
      config,
      lib,
      ...
    }:
    {
      options.mine.dev.docker.enable = lib.mkEnableOption "Docker";
      config = lib.mkIf config.mine.dev.docker.enable {
        virtualisation.docker.enable = true;
      };
    };
  flake.modules.darwin.docker =
    {
      config,
      lib,
      ...
    }:
    {
      options.mine.dev.docker.enable = lib.mkEnableOption "Docker";
      config = lib.mkIf config.mine.dev.docker.enable {
        mine.darwin.brew.casks = [ "docker" ];
      };
    };
}
