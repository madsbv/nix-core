_: {
  flake.modules.nixos.docker =
    {
      config,
      lib,
      ...
    }:
    {
      options.mine.dev.docker = {
        enable = lib.mkEnableOption "Docker";
        podman = lib.mkEnableOption "Podman alongside Docker";
      };
      config = lib.mkMerge [
        (lib.mkIf config.mine.dev.docker.enable {
          virtualisation.docker.enable = true;
        })
        (lib.mkIf config.mine.dev.docker.podman {
          virtualisation.podman.enable = true;
        })
      ];
    };
  flake.modules.darwin.docker =
    {
      config,
      lib,
      ...
    }:
    {
      options.mine.dev.docker = {
        enable = lib.mkEnableOption "Docker";
        podman = lib.mkEnableOption "Podman alongside Docker";
      };
      config = lib.mkIf config.mine.dev.docker.enable {
        mine.darwin.brew.casks = [ "docker" ];
      };
    };
}
